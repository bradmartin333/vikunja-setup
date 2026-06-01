# Vikunja Setup

This is a quick guide to get Vikunja up and running in Docker with Prometheus monitoring.

My specific setup has a few [Dockge](https://dockge.kuma.pet/) related file path differences, so I have to symlink the prometheus.yml files to the correct location: `sudo ln -s /home/dev/stacks/vikunja/prometheus.yml /opt/stacks/vikunja/prometheus.yml`
