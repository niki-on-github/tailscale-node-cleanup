FROM alpine:latest
RUN apk add --no-cache curl jq bash
WORKDIR /app
COPY setup.sh .
RUN chmod +x setup.sh
CMD ["./setup.sh"]
