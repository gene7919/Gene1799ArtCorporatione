# 🚀 Gene1799 Deployment Checklist

## Pre-Deployment (Local Testing)

- [ ] **Code Review**
  - [ ] All features working locally (`npm run dev`)
  - [ ] No console errors
  - [ ] No linting errors (`npm run lint`)
  - [ ] Tests passing (`npm run test`)

- [ ] **Environment Variables**
  - [ ] `.env` files created in all folders
  - [ ] All required variables set
  - [ ] Sensitive keys NOT committed to git
  - [ ] `.env` files in `.gitignore`

- [ ] **Dependencies**
  - [ ] `npm install` successful
  - [ ] No high-severity vulnerabilities (`npm audit`)
  - [ ] Python venv created and activated
  - [ ] `pip install -r requirements.txt` successful

- [ ] **Build Testing**
  - [ ] `npm run build` completes without errors
  - [ ] Frontend builds successfully
  - [ ] Backend build script works
  - [ ] No missing assets or files

## Render Blueprint Setup

- [ ] **Repository Setup**
  - [ ] Code pushed to GitHub (main/master branch)
  - [ ] All files committed (`.gitignore` properly configured)
  - [ ] No uncommitted changes

- [ ] **Render Dashboard**
  - [ ] Logged into Render.com
  - [ ] GitHub repository connected
  - [ ] Sufficient billing (free tier available)

- [ ] **Blueprint Configuration**
  - [ ] `render.yaml` present and valid
  - [ ] All services configured correctly
  - [ ] Database service configured (if needed)
  - [ ] Environment variables set in Render

## Deployment

- [ ] **Start Deployment**
  - [ ] Click "Deploy Blueprint" in Render
  - [ ] Monitor logs in real-time
  - [ ] Wait for all services to start (5-10 minutes)

- [ ] **Verify Services**
  - [ ] Backend health check: `/api/health`
  - [ ] Frontend loads without errors
  - [ ] AI Agent logs show initialization
  - [ ] Database connection established

- [ ] **Test Functionality**
  - [ ] Frontend can reach backend API
  - [ ] API endpoints responding correctly
  - [ ] No CORS errors in browser console
  - [ ] Database queries working

## Post-Deployment

- [ ] **Monitoring**
  - [ ] Set up Render logging alerts
  - [ ] Check Render dashboard daily
  - [ ] Monitor error rates
  - [ ] Track resource usage

- [ ] **Scaling**
  - [ ] If free tier, configure auto-scaling
  - [ ] Upgrade to paid plan if needed
  - [ ] Test load handling

- [ ] **Updates**
  - [ ] Set up GitHub Actions CI/CD
  - [ ] Automatic redeploy on push enabled
  - [ ] Slack notifications configured (optional)

- [ ] **Documentation**
  - [ ] Update deployment docs
  - [ ] Document environment variables
  - [ ] Create runbook for troubleshooting

## Troubleshooting Checklist

If services fail to start:

- [ ] Check Render logs for errors
- [ ] Verify all `render.yaml` syntax
- [ ] Confirm environment variables are set
- [ ] Check `start` scripts in package.json
- [ ] Verify Python environment in AI Agent
- [ ] Look for port conflicts
- [ ] Check build command output

Common Issues:

| Issue | Solution |
|-------|----------|
| Port already in use | Change PORT in env vars |
| Build fails | Check npm script syntax |
| Frontend can't reach API | Update VITE_API_URL env |
| Database connection error | Verify DATABASE_URL format |
| Python import errors | Check requirements.txt |
| Out of memory | Upgrade Render plan |

## Rollback Plan

If deployment has critical issues:

1. Go to Render Dashboard → Deployments
2. Click "Revert to Previous Deploy"
3. Investigate error logs
4. Fix locally and redeploy

---

**Deployment Date:** ___________
**Deployed by:** ___________
**Environment:** Production / Staging
**Status:** ✅ Live / ⏳ In Progress / ❌ Failed

**Notes:**
_________________________________
_________________________________
