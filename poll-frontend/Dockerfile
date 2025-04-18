# Use an official Nginx image as the base image
FROM nginx:stable-alpine

# Create a custom nginx config to handle API proxying
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the static content (HTML, CSS, JS) into the Nginx default public folder
COPY . /usr/share/nginx/html

# Expose port 80 (default Nginx port)
EXPOSE 80

# Nginx will start automatically when the container launches
