import os
import json
import psycopg2
from psycopg2.extras import RealDictCursor
from flask import Flask, jsonify, request
from flask_cors import CORS  # Import CORS
from dotenv import load_dotenv

# Load environment variables from .env file if present
load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes, allowing frontend JS to call the API

# Database configuration from environment variables
DB_USER = os.getenv("DB_USER", "pollapp")
DB_PASS = os.getenv("DB_PASS", "")
DB_NAME = os.getenv("DB_NAME", "pollapp")
DB_HOST = os.getenv("DB_HOST", "localhost")

# Default poll data (used if database connection fails)
DEFAULT_POLL_DATA = {
    "question": "Favorite Cloud Provider?",
    "options": ["GCP", "AWS", "Azure", "Other"],
    "votes": {"GCP": 0, "AWS": 0, "Azure": 0, "Other": 0}
}

def get_db_connection():
    """Create a database connection."""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        return conn
    except Exception as e:
        app.logger.error(f"Database connection error: {e}")
        return None

def initialize_db():
    """Initialize the database with tables and default data if needed."""
    conn = get_db_connection()
    if not conn:
        app.logger.warning("Using in-memory storage as database connection failed")
        return False
    
    try:
        with conn.cursor() as cur:
            # Create tables if they don't exist
            cur.execute('''
                CREATE TABLE IF NOT EXISTS polls (
                    id SERIAL PRIMARY KEY,
                    question TEXT NOT NULL,
                    options JSONB NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            cur.execute('''
                CREATE TABLE IF NOT EXISTS votes (
                    id SERIAL PRIMARY KEY,
                    poll_id INTEGER REFERENCES polls(id),
                    option_text TEXT NOT NULL,
                    vote_count INTEGER DEFAULT 0,
                    UNIQUE(poll_id, option_text)
                )
            ''')
            
            # Check if we already have a poll
            cur.execute("SELECT COUNT(*) FROM polls")
            poll_count = cur.fetchone()[0]
            
            if poll_count == 0:
                # Insert default poll
                cur.execute(
                    "INSERT INTO polls (question, options) VALUES (%s, %s) RETURNING id",
                    (DEFAULT_POLL_DATA["question"], json.dumps(DEFAULT_POLL_DATA["options"]))
                )
                poll_id = cur.fetchone()[0]
                
                # Insert default options with zero votes
                for option in DEFAULT_POLL_DATA["options"]:
                    cur.execute(
                        "INSERT INTO votes (poll_id, option_text, vote_count) VALUES (%s, %s, 0)",
                        (poll_id, option)
                    )
            
            conn.commit()
            return True
    except Exception as e:
        app.logger.error(f"Database initialization error: {e}")
        conn.rollback()
        return False
    finally:
        conn.close()

@app.route('/api/polls', methods=['GET'])
def get_polls():
    """Returns the current poll data including votes."""
    conn = get_db_connection()
    if not conn:
        # Fallback to in-memory data if DB connection fails
        return jsonify(DEFAULT_POLL_DATA)
    
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            # Get the most recent poll
            cur.execute("SELECT id, question, options FROM polls ORDER BY created_at DESC LIMIT 1")
            poll = cur.fetchone()
            
            if not poll:
                return jsonify(DEFAULT_POLL_DATA)
            
            # Get votes for this poll
            cur.execute("SELECT option_text, vote_count FROM votes WHERE poll_id = %s", (poll["id"],))
            votes = {row["option_text"]: row["vote_count"] for row in cur.fetchall()}
            
            # Combine poll data with votes
            poll_data = {
                "question": poll["question"],
                "options": poll["options"],
                "votes": votes
            }
            
            return jsonify(poll_data)
    except Exception as e:
        app.logger.error(f"Error fetching polls: {e}")
        return jsonify(DEFAULT_POLL_DATA)
    finally:
        conn.close()

@app.route('/api/vote', methods=['POST'])
def submit_vote():
    """Handles submission of a vote."""
    data = request.get_json()
    if not data or 'option' not in data:
        return jsonify({"error": "Missing 'option' in request body"}), 400

    selected_option = data['option']
    
    conn = get_db_connection()
    if not conn:
        # Fallback to in-memory storage if DB connection fails
        if selected_option in DEFAULT_POLL_DATA["options"]:
            DEFAULT_POLL_DATA["votes"][selected_option] += 1
            return jsonify({
                "message": "Vote submitted successfully!",
                "current_votes": DEFAULT_POLL_DATA["votes"]
            })
        else:
            return jsonify({"error": "Invalid option selected"}), 400
    
    try:
        with conn.cursor() as cur:
            # Get the most recent poll ID
            cur.execute("SELECT id, options FROM polls ORDER BY created_at DESC LIMIT 1")
            poll_result = cur.fetchone()
            
            if not poll_result:
                return jsonify({"error": "No active poll found"}), 404
            
            poll_id, options = poll_result
            
            # Check if option is valid
            if selected_option not in options:
                return jsonify({"error": "Invalid option selected"}), 400
            
            # Increment vote count
            cur.execute(
                "UPDATE votes SET vote_count = vote_count + 1 WHERE poll_id = %s AND option_text = %s",
                (poll_id, selected_option)
            )
            
            # Get updated vote counts
            cur.execute(
                "SELECT option_text, vote_count FROM votes WHERE poll_id = %s",
                (poll_id,)
            )
            votes = {row[0]: row[1] for row in cur.fetchall()}
            
            conn.commit()
            app.logger.info(f"Vote received for: {selected_option}. Current votes: {votes}")
            
            return jsonify({
                "message": "Vote submitted successfully!",
                "current_votes": votes
            })
    except Exception as e:
        conn.rollback()
        app.logger.error(f"Error submitting vote: {e}")
        return jsonify({"error": f"Database error: {str(e)}"}), 500
    finally:
        conn.close()

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint for readiness/liveness probes."""
    conn = get_db_connection()
    if conn:
        conn.close()
        return jsonify({"status": "healthy", "database": "connected"})
    return jsonify({"status": "healthy", "database": "not connected"}), 500

# Initialize the database on startup
with app.app_context():
    db_initialized = initialize_db()
    if not db_initialized:
        app.logger.warning("Database initialization failed, using in-memory storage")

if __name__ == '__main__':
    # Runs the app on http://127.0.0.1:5000 by default
    # Host='0.0.0.0' makes it accessible from other devices on the network if needed
    app.run(debug=True, host='0.0.0.0', port=5000)
