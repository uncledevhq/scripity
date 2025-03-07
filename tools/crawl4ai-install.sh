#!/bin/bash

# Exit on error
set -e

echo "Setting up CrawlNest API on Ubuntu"
echo "=================================="

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo "Installing dependencies..."
sudo apt install -y python3 python3-pip python3-venv git nginx certbot python3-certbot-nginx

# Create application directory
echo "Creating application directory..."
sudo mkdir -p /opt/crawlnest
sudo chown $USER:$USER /opt/crawlnest
cd /opt/crawlnest

# Set up virtual environment
echo "Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install required packages
echo "Installing Crawl4AI and dependencies..."
pip install -U crawl4ai fastapi uvicorn pydantic
crawl4ai-setup

# Install browser dependencies
echo "Installing browser dependencies..."
python -m playwright install --with-deps chromium

# Create application file
echo "Creating API service..."
cat > /opt/crawlnest/app.py << 'EOL'
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl
import asyncio
import uvicorn
import logging
from typing import Dict, Any, Optional, List, Union
from datetime import datetime
import os
import json
from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig, CacheMode

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("crawler.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("crawler-api")

# Create FastAPI app
app = FastAPI(
    title="CrawlNest API",
    description="API for crawling web content using Crawl4AI",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create cache directory
os.makedirs("cache", exist_ok=True)

# Define request models
class CrawlRequest(BaseModel):
    url: str
    cache: bool = True
    max_depth: int = 1
    clean_content: bool = True
    

# Define response models
class CrawlResponse(BaseModel):
    status: str
    content: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None
    timestamp: str
    url: str
    error: Optional[str] = None

# Store active crawler instance
crawler = None
crawler_lock = asyncio.Lock()

# Task tracking
tasks = {}

async def get_crawler():
    """Get or create a crawler instance."""
    global crawler
    async with crawler_lock:
        if crawler is None:
            browser_config = BrowserConfig(
                headless=True,
                verbose=False,
            )
            crawler = AsyncWebCrawler(config=browser_config)
            await crawler.start()
    return crawler

async def close_crawler():
    """Close the crawler instance if it exists."""
    global crawler
    async with crawler_lock:
        if crawler is not None:
            await crawler.close()
            crawler = None

async def crawl_url(url: str, task_id: str, cache: bool = True, max_depth: int = 1, clean_content: bool = True):
    """Crawl the URL and update the task status."""
    try:
        # Update task status
        tasks[task_id] = {"status": "processing", "url": url, "timestamp": datetime.now().isoformat()}
        
        # Set up crawler config
        cache_mode = CacheMode.ENABLED if cache else CacheMode.BYPASS
        run_config = CrawlerRunConfig(
            cache_mode=cache_mode,
            word_count_threshold=1,  # Ensure we get all content
        )
        
        # Get crawler instance
        crawler_instance = await get_crawler()
        
        # Crawl the URL
        logger.info(f"Crawling URL: {url}")
        result = await crawler_instance.arun(
            url=url,
            config=run_config
        )
        
        # Extract content based on preference
        if clean_content:
            content = result.markdown.fit_markdown
        else:
            content = result.markdown.raw_markdown
        
        # Create metadata
        metadata = {
            "title": result.page_info.title,
            "description": result.page_info.description,
            "links": result.page_info.links[:50] if result.page_info.links else [],  # Limit links to 50
            "wordCount": len(content.split()),
            "url": url,
            "crawlTime": datetime.now().isoformat()
        }
        
        # Update task with result
        tasks[task_id] = {
            "status": "completed", 
            "url": url, 
            "content": content,
            "metadata": metadata,
            "timestamp": datetime.now().isoformat()
        }
        
        # Cache the result
        if cache:
            cache_file = f"cache/{task_id}.json"
            with open(cache_file, "w") as f:
                json.dump({
                    "url": url,
                    "content": content,
                    "metadata": metadata,
                    "timestamp": datetime.now().isoformat()
                }, f)
            
        logger.info(f"Completed crawling URL: {url}")
        
    except Exception as e:
        logger.error(f"Error crawling URL {url}: {str(e)}")
        tasks[task_id] = {
            "status": "failed", 
            "url": url, 
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

@app.on_event("startup")
async def startup_event():
    logger.info("Starting the Crawl API service")

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Shutting down the Crawl API service")
    await close_crawler()

@app.post("/crawl", response_model=dict)
async def crawl(request: CrawlRequest, background_tasks: BackgroundTasks):
    """
    Crawl a URL and return its content
    """
    try:
        # Generate a task ID based on URL and timestamp
        task_id = f"{hash(request.url)}_{int(datetime.now().timestamp())}"
        
        # Check cache if enabled
        if request.cache:
            # Look for any cached file with the URL hash
            url_hash = str(hash(request.url))
            cache_files = [f for f in os.listdir("cache") if f.startswith(url_hash) and f.endswith(".json")]
            
            # If cache exists, return it
            if cache_files:
                cache_file = f"cache/{cache_files[-1]}"  # Get the most recent one
                with open(cache_file, "r") as f:
                    cached_data = json.load(f)
                return {
                    "status": "completed",
                    "task_id": task_id,
                    "message": "Retrieved from cache",
                    "data": cached_data
                }
        
        # Start crawling in background
        background_tasks.add_task(
            crawl_url, 
            request.url, 
            task_id, 
            request.cache, 
            request.max_depth,
            request.clean_content
        )
        
        return {
            "status": "accepted",
            "task_id": task_id,
            "message": "Crawling started"
        }
        
    except Exception as e:
        logger.error(f"Error starting crawl: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/task/{task_id}")
async def get_task(task_id: str):
    """
    Get the status of a crawl task
    """
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task_data = tasks[task_id]
    
    # If task is completed, clean up memory (but keep in cache)
    if task_data.get("status") in ["completed", "failed"] and "content" in task_data:
        # Copy what we need
        response_data = {
            "status": task_data["status"],
            "url": task_data["url"],
            "timestamp": task_data["timestamp"],
            "metadata": task_data.get("metadata"),
        }
        
        # Add content or error
        if task_data["status"] == "completed":
            response_data["content"] = task_data["content"]
        else:
            response_data["error"] = task_data.get("error")
            
        # Remove from memory to free up space
        if task_id in tasks:
            # Keep the task but remove the large content
            if "content" in tasks[task_id]:
                del tasks[task_id]["content"]
            
        return response_data
    
    return task_data

@app.get("/health")
async def health_check():
    """
    Health check endpoint
    """
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
EOL

# Create systemd service
echo "Creating systemd service..."
sudo bash -c 'cat > /etc/systemd/system/crawlnest.service << EOL
[Unit]
Description=CrawlNest API Service
After=network.target

[Service]
User='$USER'
Group='$USER'
WorkingDirectory=/opt/crawlnest
ExecStart=/opt/crawlnest/venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL'

# Set up Nginx
echo "Configuring Nginx..."
sudo bash -c 'cat > /etc/nginx/sites-available/crawlnest << EOL
server {
    listen 80;
    server_name crawl.chatnestai.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOL'

# Enable Nginx site
sudo ln -sf /etc/nginx/sites-available/crawlnest /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Start service
echo "Starting CrawlNest service..."
sudo systemctl enable crawlnest
sudo systemctl start crawlnest

# Set up SSL with Certbot
echo "Setting up SSL with Certbot..."
sudo certbot --nginx -d crawl.chatnestai.com --non-interactive --agree-tos --email admin@chatnestai.com

echo "Installation complete!"
echo "Your CrawlNest API is now available at https://crawl.chatnestai.com"
echo ""
echo "API Endpoints:"
echo "POST /crawl - Start crawling a URL"
echo "GET /task/{task_id} - Check the status of a crawl task"
echo "GET /health - Health check endpoint"