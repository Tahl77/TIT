FROM grafana/grafana:latest

# Copy custom configuration
COPY grafana.ini /etc/grafana/grafana.ini

# Copy provisioning configuration
COPY provisioning/ /etc/grafana/provisioning/

# Copy dashboards
COPY dashboards/ /var/lib/grafana/dashboards/

# Set permissions
USER root
RUN chown -R grafana:grafana /etc/grafana /var/lib/grafana
USER grafana

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

EXPOSE 3000