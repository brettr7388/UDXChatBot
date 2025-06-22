# 🚀 Deploy Universal Orlando API to Render (FREE)

## **Why Render?**
- **100% FREE** for basic web services
- No credit card required
- Always-on (doesn't sleep like some free tiers)
- Easy GitHub integration
- Production-ready with HTTPS

---

## **Step 1: Prepare Your Flask App for Cloud Deployment**

### **1.1 Add Gunicorn (Production Server)**
```bash
pip3 install gunicorn
pip3 freeze > requirements.txt
```

### **1.2 Create Production Configuration**
Create `config.py`:
```python
import os

class Config:
    DEBUG = False
    DEVELOPMENT = False

class ProductionConfig(Config):
    pass

class DevelopmentConfig(Config):
    DEBUG = True
    DEVELOPMENT = True
```

### **1.3 Update `predictive_in_park.py`**
Add this at the top after imports:
```python
import os

# Load configuration based on environment
env_config = os.getenv("PROD_APP_SETTINGS", "config.DevelopmentConfig")
app.config.from_object(env_config)
```

---

## **Step 2: Deploy to Render**

### **2.1 Push to GitHub**
```bash
git add .
git commit -m "Prepare for Render deployment"
git push origin main
```

### **2.2 Create Render Account**
1. Go to [render.com](https://render.com)
2. Sign up with GitHub (free, no credit card needed)

### **2.3 Create Web Service**
1. Click **"New"** → **"Web Service"**
2. Connect your GitHub repository
3. Configure deployment:

**Build Settings:**
- **Name**: `universal-orlando-api`
- **Runtime**: `Python 3`
- **Build Command**: `pip install -r requirements.txt`
- **Start Command**: `gunicorn predictive_in_park:app`

**Environment Variables:**
- `PROD_APP_SETTINGS` = `config.ProductionConfig`
- `PYTHON_VERSION` = `3.11.0`

### **2.4 Deploy**
1. Click **"Create Web Service"**
2. Wait 3-5 minutes for deployment
3. Your API will be live at: `https://your-app-name.onrender.com`

---

## **Step 3: Update Flutter App**

### **3.1 Update API URLs**
Edit `lib/services/recommendation_service.dart`:

```dart
class RecommendationService extends ChangeNotifier {
  static const List<String> _baseUrls = [
    'https://your-app-name.onrender.com',  // Your Render URL
    'http://10.132.188.218:5001',          // Keep local as backup
    'http://127.0.0.1:5001',               // Keep localhost as backup
  ];
  
  // ... rest of code stays the same
}
```

### **3.2 Test the Deployment**
```bash
# Test your deployed API
curl https://your-app-name.onrender.com/debug

# Should return wait times and ride data
```

---

## **Step 4: Benefits of This Setup**

✅ **Always Available**: API works anywhere with internet  
✅ **No Laptop Required**: Completely cloud-hosted  
✅ **Free Forever**: Render's free tier is permanent  
✅ **Automatic HTTPS**: Secure by default  
✅ **Easy Updates**: Push to GitHub → Auto-deploys  
✅ **Global CDN**: Fast worldwide access  

---

## **Step 5: Alternative Cloud Options**

### **Railway** (Usage-based pricing)
- $5 free credit (one-time)
- Pay only for what you use
- Good for occasional testing

### **Heroku** (Paid only now)
- $5-7/month minimum
- Most reliable but not free

### **PythonAnywhere** (Free tier available)
- Limited but functional free tier
- Good for small projects

---

## **Final Result**

After deployment, your app will work like this:

1. **User opens Flutter app** → Works anywhere
2. **App needs recommendation** → Calls `https://your-app.onrender.com/recommend`
3. **API fetches live wait times** → From queue-times.com
4. **Returns smart recommendation** → Based on location and wait times
5. **User gets directions** → Via Google Maps

**No laptop required!** 🎉

---

## **Troubleshooting**

### **If deployment fails:**
- Check build logs in Render dashboard
- Ensure `requirements.txt` includes all dependencies
- Verify `gunicorn` is in requirements.txt

### **If API is slow:**
- First request might be slow (cold start)
- Subsequent requests will be fast
- Consider upgrading to paid tier for instant responses

### **If Flutter can't connect:**
- Check the URL is correct
- Test API manually: `https://your-app.onrender.com/debug`
- Ensure CORS is properly configured in Flask app 