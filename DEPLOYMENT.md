# Deployment Guide - GitHub Pages

This guide explains how to deploy the Flame MCP Server as a hosted service using GitHub Actions and GitHub Pages.

## 🎯 Overview

Instead of running the MCP server locally, users will be able to use a URL in their MCP configuration that points to your hosted service. The service will:

- Automatically sync Flame documentation daily at 2 AM UTC
- Serve documentation via a static API hosted on GitHub Pages
- Provide search functionality through the hosted API
- Update automatically when you push changes

## 🚀 Setup Steps

### 1. Push to GitHub

First, push your repository to GitHub:

```bash
# Add all files
git add .

# Commit changes
git commit -m "Add GitHub Actions deployment setup"

# Create GitHub repository and push
# (Replace with your actual GitHub username/repo)
git remote add origin https://github.com/yourusername/flame_mcp_server.git
git push -u origin main
```

### 2. Enable GitHub Pages

1. Go to your GitHub repository
2. Click **Settings** tab
3. Scroll down to **Pages** section
4. Under **Source**, select **GitHub Actions**
5. Save the settings

### 3. Configure Repository Permissions

1. In your repository, go to **Settings** → **Actions** → **General**
2. Under **Workflow permissions**, select **Read and write permissions**
3. Check **Allow GitHub Actions to create and approve pull requests**
4. Click **Save**

### 4. Trigger First Deployment

The GitHub Action will run automatically when you push to main, but you can also trigger it manually:

1. Go to **Actions** tab in your repository
2. Click on **Sync Flame Documentation** workflow
3. Click **Run workflow** button
4. Select **main** branch and click **Run workflow**

### 5. Wait for Deployment

The workflow will:
1. ✅ Sync documentation from Flame GitHub repository (~84 files)
2. ✅ Generate static API files
3. ✅ Deploy to GitHub Pages

This takes about 2-3 minutes.

### 6. Get Your Hosted URL

Once deployed, your service will be available at:
```
https://yourusername.github.io/flame_mcp_server/
```

Replace `yourusername` with your actual GitHub username.

## 🔧 User Configuration

Users can now add your hosted service to their MCP configuration:

### Claude Desktop Configuration

```json
{
  "mcpServers": {
    "flame-docs": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch", "https://yourusername.github.io/flame_mcp_server/"]
    }
  }
}
```

### Generic MCP Configuration

```json
{
  "servers": {
    "flame-docs": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch", "https://yourusername.github.io/flame_mcp_server/"],
      "description": "Hosted Flame game engine documentation"
    }
  }
}
```

## 📊 What Gets Deployed

The GitHub Action creates these files on GitHub Pages:

```
https://yourusername.github.io/flame_mcp_server/
├── index.html              # Landing page with instructions
├── server-info.json        # MCP server information
├── resources.json          # List of all documentation resources
├── tools.json             # Available MCP tools
├── search-index.json      # Search index for documentation
└── resources/             # Individual documentation files
    ├── getting_started.json
    ├── components_component_system.json
    ├── rendering_rendering.json
    └── ... (80+ more files)
```

## 🔄 Automatic Updates

The service will automatically update:

- **Daily at 2 AM UTC** - Syncs latest documentation from Flame repository
- **On every push to main** - Redeploys with any code changes
- **Manual trigger** - You can run the workflow manually anytime

## 🐛 Troubleshooting

### Workflow Fails

**Check the Actions tab** for error details:
1. Go to **Actions** tab
2. Click on the failed workflow run
3. Expand the failed step to see error details

**Common issues:**
- **Permissions**: Ensure workflow has read/write permissions
- **Pages not enabled**: Make sure GitHub Pages is enabled with "GitHub Actions" source
- **Rate limiting**: The workflow uses `GITHUB_TOKEN` automatically, but you can add a personal access token if needed

### Service Not Accessible

**Check deployment status:**
1. Go to **Actions** tab
2. Verify the latest workflow completed successfully
3. Check **Settings** → **Pages** for deployment status

**Test the API endpoints:**
- Visit `https://yourusername.github.io/flame_mcp_server/` (should show landing page)
- Test `https://yourusername.github.io/flame_mcp_server/server-info.json` (should return JSON)

### Users Can't Connect

**Verify MCP configuration:**
- Ensure users have `@modelcontextprotocol/server-fetch` package available
- Check the URL is correct (no trailing slashes)
- Test with MCP Inspector: `npx @modelcontextprotocol/inspector npx -y @modelcontextprotocol/server-fetch https://yourusername.github.io/flame_mcp_server/`

## 📈 Monitoring

You can monitor your service:

- **GitHub Actions**: See sync history and any failures
- **GitHub Pages**: Check deployment status and traffic
- **Repository Insights**: See how many people are using your service

## 🔒 Security

The service is read-only and doesn't store any user data:
- Only serves public Flame documentation
- No authentication required
- No user data collection
- All code is open source

## 💡 Customization

You can customize the service by modifying:

- **Sync schedule**: Edit `.github/workflows/sync-docs.yml` cron expression
- **Documentation source**: Modify `lib/src/flame_live_docs.dart` to use different repositories
- **API structure**: Update `bin/generate_static_api.dart` to change the API format
- **Landing page**: Edit the HTML template in `bin/generate_static_api.dart`

---

**Ready to deploy?** Push your code to GitHub and enable GitHub Pages!
