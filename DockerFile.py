# Use an official Ubuntu as the base image
FROM ubuntu:latest

# Set the working directory inside the container
WORKDIR /app

# Install dependencies (Zenity, bash, etc.)
RUN apt-get update && apt-get install -y \
    zenity \
    smartmontools \
    iproute2 \
    net-tools \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copy everything from the current directory (gasser/) to the /app directory in the container
COPY . /app

# Set executable permissions on the project script
RUN chmod +x /app/project.sh

# Set the default command to run when the container starts
CMD ["/bin/bash", "/app/project.sh"]
