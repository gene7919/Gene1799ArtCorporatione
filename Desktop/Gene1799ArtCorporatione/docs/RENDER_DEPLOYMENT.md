# Deployment Guide for Gene1799 on Render

## Quick Start with Render

### Prerequisites
- GitHub account with repository access
- Render.com account (free tier available)

### Deployment Steps

1. **Connect Repository to Render**
   - Go to https://dashboard.render.com
   - Click "New +" → "Blueprint"
   - Select your GitHub repository
   - Authorize Render

2. **Configure Services**
   The `render.yaml` file automatically configures:
   - **Backend API** (Node.js) on port 10000
   - **Frontend** (Static site with Vite build)
   - **AI Agent** (Python background worker)

3. **Set Environment Variables**
   In Render Dashboard, set:
   ```
   NODE_ENV=production
   DATABASE_URL=<your-database-url>
   API_KEY=<generate-secure-key>
   LOG_LEVEL=info
   ```

4. **Deploy**
   - Click "Deploy"
   - Render will automatically build and deploy all services
   - Check progress in the Dashboard

### Service URLs (after deployment)
- Backend API: `https://gene1799-backend.onrender.com`
- Frontend: `https://gene1799-frontend.onrender.com`
- AI Agent: `https://gene1799-agent.onrender.com`

### Important Notes

#### Plans
- **Free Plan**: Limited resources, will spin down after 15 min of inactivity
- **Starter Plan** ($12/mo): Recommended for production with persistent uptime

#### Database
- PostgreSQL is included in `render.yaml` (free tier)
- Update `.env` with `DATABASE_URL` in production

#### Scaling
- Backend: Can auto-scale with traffic
- Frontend: Static site (no scaling needed)
- AI Agent: Single instance (can upgrade plan if needed)

### Monitoring

View logs:
```
Render Dashboard → Your Service → Logs
```

Set up alerts for errors:
```
Render Dashboard → Email Notifications
```

### Troubleshooting

**Service won't start?**
- Check logs in Render Dashboard
- Verify `start` script in package.json
- Ensure all env vars are set

**Frontend not loading?**
- Check `VITE_API_URL` points to backend
- Verify CORS is enabled in backend
- Clear cache and rebuild

**AI Agent not connecting?**
- Verify backend service is running
- Check `API_HOST` and `API_PORT` in env vars
- Review logs for connection errors

## Manual Deployment (Advanced)

If not using Render Blueprint:

```bash
# Build backend
npm -w backend run build

# Build frontend
npm -w frontend run build

# Deploy each service:
# - Backend: Deploy backend/ folder
# - Frontend: Deploy frontend/dist folder  
# - AI Agent: Deploy ai-agent/ folder with Python env
```

## Continuous Deployment

Render automatically redeploys when:
- Push to main/master branch
- Merge a pull request
- Manual redeploy from dashboard

To disable auto-deploy:
- Render Dashboard → Service Settings → Disable auto-deploy

---
**Last Updated:** 2026-02-08
**Version:** 1.0.0
