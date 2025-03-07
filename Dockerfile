FROM hashicorp/terraform:latest

# Install required packages
RUN apk add --no-cache \
    bash \
    curl \
    python3 \
    py3-pip \
    git \
    jq \
    aws-cli \
    nodejs \
    npm \
    && rm -rf /var/cache/apk/*

# Install latest Google Cloud SDK
RUN curl -O https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz && \
    tar zxvf google-cloud-sdk.tar.gz && \
    rm google-cloud-sdk.tar.gz && \
    ./google-cloud-sdk/install.sh --quiet --path-update=true --usage-reporting=false --additional-components alpha beta && \
    ln -s /google-cloud-sdk/bin/gcloud /usr/local/bin/ && \
    ln -s /google-cloud-sdk/bin/gsutil /usr/local/bin/

# Set up working directory
WORKDIR /workspace

# Copy scripts
COPY scripts /workspace/scripts

# Set up bash environment
RUN echo "source /workspace/scripts/funcs" >> ~/.bashrc

# Copy entrypoint script
COPY scripts/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bash"] 