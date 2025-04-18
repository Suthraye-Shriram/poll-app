console.log("Frontend loaded");

// Handle both local development and containerized environments
let API_BASE_URL;

// Determine if we're running in development or production
if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    // In local development, use localhost:5000
    API_BASE_URL = 'http://localhost:5000/api';
} else {
    // In production or when containerized, use the relative path
    // This will handle requests to the same host but different port
    API_BASE_URL = '/api';
}

console.log("Using API URL:", API_BASE_URL);

function displayPoll(pollData) {
    console.log("Displaying poll data:", pollData);
    const pollContainer = document.getElementById('poll-container');
    if (!pollContainer) {
        console.error('Poll container element not found!');
        return;
    }

    // Clear previous content
    pollContainer.innerHTML = '';

    // Display the question
    const questionElement = document.createElement('h3');
    questionElement.textContent = pollData.question;
    pollContainer.appendChild(questionElement);

    // Create a form for the options
    const form = document.createElement('form');
    form.id = 'poll-form';

    // Display the options as radio buttons and show votes
    const optionsList = document.createElement('ul');
    optionsList.style.listStyle = 'none'; // Remove default list styling
    optionsList.style.padding = '0';

    pollData.options.forEach(option => {
        const voteCount = pollData.votes[option] || 0; // Get vote count, default to 0
        const listItem = document.createElement('li');
        listItem.style.margin = '5px 0';

        const radioInput = document.createElement('input');
        radioInput.type = 'radio';
        radioInput.name = 'pollOption'; // Group radio buttons
        radioInput.value = option;
        radioInput.id = `option-${option.replace(/\s+/g, '-')}`; // Create a unique ID

        const label = document.createElement('label');
        label.htmlFor = radioInput.id;
        // Display option text and current vote count
        label.textContent = ` ${option} (${voteCount} votes)`;
        label.style.marginLeft = '5px';

        listItem.appendChild(radioInput);
        listItem.appendChild(label);
        optionsList.appendChild(listItem);
    });
    form.appendChild(optionsList);

    // Add a submit button
    const submitButton = document.createElement('button');
    submitButton.type = 'submit'; // Make it a submit button for the form
    submitButton.textContent = 'Vote';
    form.appendChild(submitButton);

    pollContainer.appendChild(form);

    // Add event listener to the form for submission
    form.addEventListener('submit', handleVoteSubmit);
}

function handleVoteSubmit(event) {
    event.preventDefault(); // Prevent default form submission (page reload)

    const selectedOptionInput = document.querySelector('input[name="pollOption"]:checked');

    if (!selectedOptionInput) {
        alert('Please select an option to vote.');
        return;
    }

    const selectedOption = selectedOptionInput.value;
    console.log(`Submitting vote for: ${selectedOption}`);

    // Send vote to the backend
    fetch(`${API_BASE_URL}/vote`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ option: selectedOption }),
    })
    .then(response => {
        if (!response.ok) {
            // Try to get error message from backend if available
            return response.json().then(err => { throw new Error(err.error || `HTTP error! status: ${response.status}`) });
        }
        return response.json();
    })
    .then(data => {
        console.log("Vote submission response:", data);
        // Re-fetch poll data to show updated results
        fetchPolls();
        // Optionally, display a success message
        // alert(data.message);
    })
    .catch(error => {
        console.error('Error submitting vote:', error);
        alert(`Error submitting vote: ${error.message}. Please try again.`);
    });
}


function fetchPolls() {
    fetch(`${API_BASE_URL}/polls`)
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            displayPoll(data); // Use the new function to display poll data
        })
        .catch(error => {
            console.error('Error fetching polls:', error);
            const pollContainer = document.getElementById('poll-container');
            if (pollContainer) {
                pollContainer.innerHTML = '<p>Error loading poll data. Is the backend running and accessible?</p>';
            }
        });
}

// Fetch polls when the script loads
fetchPolls();
