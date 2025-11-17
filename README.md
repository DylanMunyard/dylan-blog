# Dylan's Technical Blog

A modern, fast technical blog built with [Astro](https://astro.build) featuring a unique terminal-inspired design.

## Features

- 🚀 **Lightning Fast** - Built with Astro for optimal performance
- 📝 **Markdown-based** - Write posts in `.md` files with frontmatter
- 🎨 **Terminal Aesthetic** - Unique monospace design with dark/light themes
- 💻 **Code Highlighting** - Beautiful syntax highlighting with Dracula theme
- 📱 **Responsive** - Works great on all devices
- 📡 **RSS Feed** - Subscribe at `/rss.xml`

## Writing Blog Posts

Create a new markdown file in `src/content/blog/`:

```markdown
---
title: "Your Post Title"
description: "A short description"
date: 2025-01-15
tags: ["linux", "programming"]
draft: false
---

Your content here...
```

The blog automatically sorts posts by date - no manual ordering needed!

## Development

```bash
npm install
npm run dev
```

Visit `http://localhost:4321`

## Building

```bash
npm run build
```

Output is in `dist/` directory.

## Deployment

The blog is containerized with Docker and deployed to Kubernetes:

```bash
docker build -f deploy/Dockerfile -t dylan-blog .
```

### Jenkins

Plugins used:
- [Kubernetes CLI](https://plugins.jenkins.io/kubernetes-cli/) for running kubectl commands
- [Kubernetes](https://github.com/jenkinsci/kubernetes-plugin/tree/master) for running build agents as pods

### Deploy

- Manually deploy [deployment-manager.yaml](./deploy/app/deployment-manager.yaml) to create a role binding between the jenkins default service account and the blog namespace. This will give the pod service account used by the Jenkins agents access to deploy the blog.

## Project Structure

```
/
├── public/           # Static assets (images, favicon)
├── src/
│   ├── content/
│   │   └── blog/     # Blog posts (.md files)
│   ├── layouts/      # Page layouts
│   ├── pages/        # Routes and pages
│   └── styles/       # Global CSS
├── astro.config.mjs  # Astro configuration
└── package.json
```
