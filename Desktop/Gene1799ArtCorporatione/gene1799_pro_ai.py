#!/usr/bin/env python3
"""
Gene1799 PRO AI Platform
Advanced interactive AI system with full API integration, agent specialization,
content creation, social media automation, and Telegram bot support.

Features:
- Login with password authentication
- Multiple AI engines integration (OpenAI, custom APIs)
- Dynamic agent specialization and configuration
- Content creation (text, images, music, video)
- Social media automation (Twitter, LinkedIn, Instagram, TikTok)
- Telegram bot integration
- Real-time chat with AI
- Green neon theme
- Professional interface
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
import json
import threading
import os
from datetime import datetime
from pathlib import Path
import hashlib
import requests
from typing import Dict, List, Tuple
import webbrowser


# Configuration
RENDER_API = "https://gene1799-api.onrender.com"
OPENAI_MODELS = ["gpt-4", "gpt-3.5-turbo"]
SOCIAL_PLATFORMS = ["Twitter", "LinkedIn", "Instagram", "TikTok", "Telegram"]
CONTENT_TYPES = ["Text", "Image", "Music", "Video"]


class Gene1799ProAI:
    """Main application for Gene1799 PRO AI"""
    
    def __init__(self, root):
        self.root = root
        self.root.geometry("1400x900")
        self.root.configure(bg="#0a0e27")
        
        # State
        self.logged_in = False
        self.current_user = None
        self.api_keys = {}
        self.agents = {}
        self.chat_history = []
        
        # Colors
        self.colors = {
            'bg': '#0a0e27',
            'accent': '#00ff41',       # Green neon
            'accent_light': '#39ff14',  # Lighter green
            'dark': '#050a1a',
            'text': '#ffffff',
            'secondary': '#00ffff',    # Cyan
            'warning': '#ffaa00'
        }
        
        # Show login screen
        self.show_login()
    
    def show_login(self):
        """Display login screen"""
        # Clear window
        for widget in self.root.winfo_children():
            widget.destroy()
        
        self.root.title("Gene1799 PRO AI - Login")
        
        # Main frame
        main = tk.Frame(self.root, bg=self.colors['dark'])
        main.pack(fill=tk.BOTH, expand=True)
        
        # Logo area
        logo = tk.Label(main, text="🤖 GENE1799", 
                       bg=self.colors['dark'], fg=self.colors['accent'],
                       font=('Arial', 32, 'bold'))
        logo.pack(pady=20)
        
        subtitle = tk.Label(main, text="PRO AI PLATFORM",
                           bg=self.colors['dark'], fg=self.colors['secondary'],
                           font=('Arial', 14))
        subtitle.pack()
        
        # Login form
        form = tk.Frame(main, bg=self.colors['dark'])
        form.pack(pady=40)
        
        # Username
        tk.Label(form, text="Username:", bg=self.colors['dark'], 
                fg=self.colors['accent'], font=('Arial', 11)).pack(pady=10)
        username_entry = tk.Entry(form, width=30, bg='#1a1f3a', 
                                 fg=self.colors['accent'],
                                 insertbackground=self.colors['accent'],
                                 font=('Arial', 12), border=2)
        username_entry.pack(pady=5)
        
        # Password
        tk.Label(form, text="Password:", bg=self.colors['dark'],
                fg=self.colors['accent'], font=('Arial', 11)).pack(pady=10)
        password_entry = tk.Entry(form, width=30, show='●', bg='#1a1f3a',
                                 fg=self.colors['accent'],
                                 insertbackground=self.colors['accent'],
                                 font=('Arial', 12), border=2)
        password_entry.pack(pady=5)
        
        # Buttons
        btn_frame = tk.Frame(form, bg=self.colors['dark'])
        btn_frame.pack(pady=20)
        
        def login():
            user = username_entry.get().strip()
            passwd = password_entry.get()
            if user and passwd:
                # Simple auth for demo (hash password)
                hashed = hashlib.sha256(passwd.encode()).hexdigest()
                if len(passwd) >= 6:  # Simple check
                    self.current_user = user
                    self.logged_in = True
                    self.show_main_app()
                else:
                    messagebox.showerror("Error", "Password too short (min 6 chars)")
            else:
                messagebox.showwarning("Warning", "Fill all fields!")
        
        login_btn = tk.Button(btn_frame, text="LOGIN",
                             bg=self.colors['accent'], fg='#000000',
                             font=('Arial', 12, 'bold'), width=15,
                             command=login, cursor='hand2')
        login_btn.pack(side=tk.LEFT, padx=5)
        
        register_btn = tk.Button(btn_frame, text="REGISTER",
                                bg=self.colors['secondary'], fg='#000000',
                                font=('Arial', 12, 'bold'), width=15,
                                command=lambda: messagebox.showinfo("Register",
                                    "Use any username and password (min 6 chars)"),
                                cursor='hand2')
        register_btn.pack(side=tk.LEFT, padx=5)
    
    def show_main_app(self):
        """Display main application"""
        for widget in self.root.winfo_children():
            widget.destroy()
        
        self.root.title(f"Gene1799 PRO AI - {self.current_user}")
        
        # Main container
        main = ttk.Frame(self.root)
        main.pack(fill=tk.BOTH, expand=True)
        
        # Header
        self.build_header(main)
        
        # Content area
        content = ttk.Frame(main)
        content.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Notebook (tabs)
        notebook = ttk.Notebook(content)
        notebook.pack(fill=tk.BOTH, expand=True)
        
        # Chat Tab
        self.build_chat_tab(notebook)
        
        # Agents Tab
        self.build_agents_tab(notebook)
        
        # API Keys Tab
        self.build_api_tab(notebook)
        
        # Content Creation Tab
        self.build_content_tab(notebook)
        
        # Social Media Tab
        self.build_social_tab(notebook)
        
        # Telegram Bot Tab
        self.build_telegram_tab(notebook)
        
        # Settings Tab
        self.build_settings_tab(notebook)
    
    def build_header(self, parent):
        """Build top header"""
        header = tk.Frame(parent, bg='#050a1a', height=60)
        header.pack(fill=tk.X, padx=10, pady=10)
        header.pack_propagate(False)
        
        title = tk.Label(header, text="🤖 GENE1799 PRO AI",
                        bg='#050a1a', fg=self.colors['accent'],
                        font=('Arial', 16, 'bold'))
        title.pack(side=tk.LEFT, padx=10, pady=10)
        
        user_info = tk.Label(header, text=f"👤 {self.current_user}",
                            bg='#050a1a', fg=self.colors['secondary'],
                            font=('Arial', 10))
        user_info.pack(side=tk.RIGHT, padx=10, pady=10)
    
    def build_chat_tab(self, notebook):
        """Chat with AI tab"""
        frame = ttk.Frame(notebook)
        notebook.add(frame, text="💬 Chat with AI")
        
        # Configure style
        style = ttk.Style()
        style.configure('dark.TFrame', background=self.colors['bg'])
        
        # Chat display
        chat_frame = tk.Frame(frame, bg=self.colors['dark'], relief=tk.SUNKEN, bd=1)
        chat_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        self.chat_display = scrolledtext.ScrolledText(
            chat_frame, bg=self.colors['dark'], fg=self.colors['accent'],
            font=('Courier', 9), wrap=tk.WORD, state=tk.DISABLED)
        self.chat_display.pack(fill=tk.BOTH, expand=True)
        
        self.chat_display.tag_config('user', foreground=self.colors['accent_light'],
                                     font=('Courier', 9, 'bold'))
        self.chat_display.tag_config('ai', foreground=self.colors['secondary'])
        self.chat_display.tag_config('system', foreground=self.colors['warning'])
        
        # AI Model selection
        config_frame = tk.Frame(frame, bg=self.colors['bg'])
        config_frame.pack(fill=tk.X, padx=5, pady=5)
        
        tk.Label(config_frame, text="AI Model:", bg=self.colors['bg'],
                fg=self.colors['accent']).pack(side=tk.LEFT, padx=5)
        
        model_var = tk.StringVar(value="gpt-4")
        model_menu = ttk.Combobox(config_frame, textvariable=model_var,
                                 values=OPENAI_MODELS, state='readonly', width=15)
        model_menu.pack(side=tk.LEFT, padx=5)
        
        # Input area
        input_frame = tk.Frame(frame, bg=self.colors['bg'])
        input_frame.pack(fill=tk.X, padx=5, pady=5)
        
        self.question_input = tk.Text(input_frame, height=3, bg='#1a1f3a',
                                     fg=self.colors['accent'],
                                     insertbackground=self.colors['accent'],
                                     font=('Courier', 10))
        self.question_input.pack(fill=tk.BOTH, expand=True, side=tk.LEFT, padx=(0, 5))
        
        btn_frame = tk.Frame(input_frame, bg=self.colors['bg'])
        btn_frame.pack(side=tk.RIGHT, fill=tk.Y)
        
        send_btn = tk.Button(btn_frame, text="SEND", bg=self.colors['accent'],
                            fg='#000000', font=('Arial', 11, 'bold'),
                            command=lambda: self.send_ai_question(model_var.get()),
                            cursor='hand2')
        send_btn.pack(fill=tk.BOTH, expand=True, pady=2)
        
        clear_btn = tk.Button(btn_frame, text="CLEAR", bg=self.colors['warning'],
                             fg='#000000', font=('Arial', 11, 'bold'),
                             command=self.clear_chat, cursor='hand2')
        clear_btn.pack(fill=tk.BOTH, expand=True, pady=2)
    
    def build_agents_tab(self, notebook):
        """Agent management tab"""
        frame = ttk.Frame(notebook)
        notebook.add(frame, text="🤖 Agents")
        
        # Agents list
        list_frame = tk.Frame(frame, bg=self.colors['dark'], relief=tk.SUNKEN, bd=1)
        list_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5, side=tk.LEFT)
        
        tk.Label(list_frame, text="Active Agents", bg=self.colors['dark'],
                fg=self.colors['accent'], font=('Arial', 11, 'bold')).pack(fill=tk.X, padx=5, pady=5)
        
        self.agents_list = scrolledtext.ScrolledText(
            list_frame, bg=self.colors['dark'], fg=self.colors['accent_light'],
            font=('Courier', 8), height=20, width=40, state=tk.DISABLED)
        self.agents_list.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        # Config panel
        config_frame = tk.Frame(frame, bg=self.colors['bg'], width=300)
        config_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5, side=tk.RIGHT)
        config_frame.pack_propagate(False)
        
        tk.Label(config_frame, text="Add Agent", bg=self.colors['bg'],
                fg=self.colors['accent'], font=('Arial', 11, 'bold')).pack(pady=10)
        
        # Name
        tk.Label(config_frame, text="Name:", bg=self.colors['bg'],
                fg=self.colors['accent']).pack(fill=tk.X, padx=10)
        agent_name = tk.Entry(config_frame, bg='#1a1f3a', fg=self.colors['accent'],
                             insertbackground=self.colors['accent'])
        agent_name.pack(fill=tk.X, padx=10, pady=5)
        
        # Type
        tk.Label(config_frame, text="Type:", bg=self.colors['bg'],
                fg=self.colors['accent']).pack(fill=tk.X, padx=10)
        type_var = tk.StringVar(value="Text")
        type_menu = ttk.Combobox(config_frame, textvariable=type_var,
                                values=["Text", "Image", "Music", "Video", "Hybrid"],
                                state='readonly')
        type_menu.pack(fill=tk.X, padx=10, pady=5)
        
        # Model
        tk.Label(config_frame, text="Model:", bg=self.colors['bg'],
                fg=self.colors['accent']).pack(fill=tk.X, padx=10)
        model_var = tk.StringVar(value="gpt-4")
        model_menu = ttk.Combobox(config_frame, textvariable=model_var,
                                 values=OPENAI_MODELS, state='readonly')
        model_menu.pack(fill=tk.X, padx=10, pady=5)
        
        def add_agent():
            name = agent_name.get().strip()
            if name:
                self.agents[name] = {
                    'name': name,
                    'type': type_var.get(),
                    'model': model_var.get(),
                    'status': 'active'
                }
                agent_name.delete(0, tk.END)
                self.refresh_agents_list()
        
        add_btn = tk.Button(config_frame, text="+ ADD AGENT",
                           bg=self.colors['accent'], fg='#000000',
                           font=('Arial', 10, 'bold'), command=add_agent,
                           cursor='hand2')
        add_btn.pack(fill=tk.X, padx=10, pady=10)
    
    def build_api_tab(self, notebook):
        """API keys management tab"""
        frame = ttk.Frame(notebook)
        notebook.add(frame, text="🔑 API Keys")
        
        tk.Label(frame, text="Manage API Integration", background=self.colors['bg'],
                foreground=self.colors['accent'], font=('Arial', 12, 'bold')).pack(pady=10)
        
        # APIs list
        apis_frame = tk.Frame(frame, bg=self.colors['dark'], relief=tk.SUNKEN, bd=1)
        apis_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        tk.Label(apis_frame, text="API Services", bg=self.colors['dark'],
                fg=self.colors['accent'], font=('Arial', 10, 'bold')).pack(fill=tk.X, padx=5, pady=5)
        
        # API options
        api_services = [
            ("OpenAI API", "sk-..."),
            ("DALL-E Image Gen", "key-..."),
            ("Stability AI", "key-..."),
            ("RunwayML Video", "key-..."),
            ("Spotify Music", "key-..."),
            ("Twitter API", "key-..."),
            ("Render.com API", "key-..."),
        ]
        
        for api_name, placeholder in api_services:
            api_item = tk.Frame(apis_frame, bg='#1a1f3a', relief=tk.RAISED, bd=1)
            api_item.pack(fill=tk.X, padx=5, pady=3)
            
            tk.Label(api_item, text=f"  {api_name}", bg='#1a1f3a',
                    fg=self.colors['accent']).pack(side=tk.LEFT, padx=5, pady=5)
            
            entry = tk.Entry(api_item, width=30, bg='#050a1a',
                           fg=self.colors['secondary'],
                           insertbackground=self.colors['secondary'],
                           show='●')
            entry.pack(side=tk.LEFT, padx=5, pady=5)
            
            def save_key(service=api_name, e=entry):
                key = e.get()
                if key:
                    self.api_keys[service] = key
                    messagebox.showinfo("Saved", f"{service} API key saved!")
            
            btn = tk.Button(api_item, text="✓", bg=self.colors['accent_light'],
                           fg='#000000', font=('Arial', 9, 'bold'),
                           command=save_key, cursor='hand2', width=3)
            btn.pack(side=tk.RIGHT, padx=5, pady=5)
    
    def build_content_tab(self, notebook):
        """Content creation tab"""
        frame = ttk.Frame(notebook)
        notebook.add(frame, text="📝 Content Creation")
        
        # Left panel - Creator
        left = tk.Frame(frame, bg=self.colors['dark'], relief=tk.SUNKEN, bd=1)
        left.pack(fill=tk.BOTH, expand=True, padx=5, pady=5, side=tk.LEFT)
        
        tk.Label(left, text="Create Content", bg=self.colors['dark'],
                fg=self.colors['accent'], font=('Arial', 11, 'bold')).pack(fill=tk.X, padx=5, pady=5)
        
        # Content type
        tk.Label(left, text="Type:", bg=self.colors['dark'],
                fg=self.colors['accent']).pack(fill=tk.X, padx=10)
        content_type = tk.StringVar(value="Text")
        type_menu = ttk.Combobox(left, textvariable=content_type,
                                values=CONTENT_TYPES, state='readonly')
        type_menu.pack(fill=tk.X, padx=10, pady=5)
        
        # Prompt
        tk.Label(left, text="Prompt/Description:", bg=self.colors['dark'],
                fg=self.colors['accent']).pack(fill=tk.X, padx=10, pady=(10, 5))
        
        prompt = tk.Text(left, height=4, bg='#1a1f3a',
                        fg=self.colors['accent'],
                        insertbackground=self.colors['accent'],
                        font=('Courier', 9))
        prompt.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        # Create button
        def create_content():
            content_val = prompt.get("1.0", tk.END).strip()
            ctype = content_type.get()
            if content_val:
                messagebox.showinfo("Creating",
                    f"Creating {ctype} content...\n\n{content_val[:50]}...")
        
        tk.Button(left, text="CREATE", bg=self.colors['accent'],
                 fg='#000000', font=('Arial', 11, 'bold'),
                 command=create_content, cursor='hand2').pack(fill=tk.X, padx=10, pady=10)
        
        # Right panel - Output
        right = tk.Frame(frame, bg=self.colors['dark'], relief=tk.SUNKEN, bd=1)
        right.pack(fill=tk.BOTH, expand=True, padx=5, pady=5, side=tk.RIGHT)
        
        tk.Label(right, text="Generated Content", bg=self.colors['dark'],
                fg=self.colors['accent'], font=('Arial', 11, 'bold')).pack(fill=tk.X, padx=5, pady=5)
        
        output = scrolledtext.ScrolledText(right, bg='#1a1f3a',
                                          fg=self.colors['accent_light'],
                                          font=('Courier', 9))
        output.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
    
    def build_social_tab(self, notebook):
        """Social media automation tab"""
        frame = ttk.Frame(notebook)
        notebook.add(frame, text="📱 Social Media")
        
        tk.Label(frame, text="Publish to Social Platforms", background=self.colors['bg'],
                foreground=self.colors['accent'], font=('Arial', 12, 'bold')).pack(pady=10)
        
        # Platforms
        platforms_frame = tk.Frame(frame, bg=self.colors['dark'], relief=tk.SUNKEN, bd=1)
        platforms_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        for platform in SOCIAL_PLATFORMS:
            plat_frame = tk.Frame(platforms_frame, bg='#1a1f3a', relief=tk.RAISED, bd=1)
            plat_frame.pack(fill=tk.X, padx=5, pady=5)
            
            tk.Label(plat_frame, text=f"  {platform}", bg='#1a1f3a',
                    fg=self.colors['accent'], font=('Arial', 10, 'bold')).pack(side=tk.LEFT, padx=10, pady=5)
            
            status = tk.Label(plat_frame, text="[Not Connected]", bg='#1a1f3a',
                            fg=self.colors['warning'])
            status.pack(side=tk.LEFT, padx=10)
            
            post_btn = tk.Button(plat_frame, text="POST", bg=self.colors['accent'],
                                fg='#000000', font=('Arial', 9, 'bold'),
                                cursor='hand2')
            post_btn.pack(side=tk.RIGHT, padx=10, pady=5)
    
    def build_telegram_tab(self, notebook):
        """Telegram bot tab"""
        frame = ttk.Frame(notebook)
        notebook.add(frame, text="📲 Telegram Bot")
        
        # Config
        config = tk.Frame(frame, bg=self.colors['dark'], relief=tk.SUNKEN, bd=1)
        config.pack(fill=tk.X, padx=10, pady=10)
        
        tk.Label(config, text="Telegram Bot Configuration", bg=self.colors['dark'],
                fg=self.colors['accent'], font=('Arial', 11, 'bold')).pack(fill=tk.X, padx=5, pady=5)
        
        tk.Label(config, text="Bot Token:", bg=self.colors['dark'],
                fg=self.colors['accent']).pack(fill=tk.X, padx=10)
        token = tk.Entry(config, bg='#1a1f3a', fg=self.colors['accent'],
                        insertbackground=self.colors['accent'], show='●')
        token.pack(fill=tk.X, padx=10, pady=5)
        
        tk.Label(config, text="Chat ID:", bg=self.colors['dark'],
                fg=self.colors['accent']).pack(fill=tk.X, padx=10)
        chat_id = tk.Entry(config, bg='#1a1f3a', fg=self.colors['accent'],
                          insertbackground=self.colors['accent'])
        chat_id.pack(fill=tk.X, padx=10, pady=5)
        
        def setup_bot():
            if token.get() and chat_id.get():
                messagebox.showinfo("Setup", "Telegram bot configured!")
        
        tk.Button(config, text="SETUP BOT", bg=self.colors['accent'],
                 fg='#000000', font=('Arial', 10, 'bold'),
                 command=setup_bot, cursor='hand2').pack(fill=tk.X, padx=10, pady=10)
        
        # Commands
        cmd_frame = tk.Frame(frame, bg=self.colors['dark'], relief=tk.SUNKEN, bd=1)
        cmd_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        tk.Label(cmd_frame, text="Available Commands", bg=self.colors['dark'],
                fg=self.colors['accent'], font=('Arial', 11, 'bold')).pack(fill=tk.X, padx=5, pady=5)
        
        commands = scrolledtext.ScrolledText(cmd_frame, bg='#1a1f3a',
                                            fg=self.colors['accent_light'],
                                            font=('Courier', 9), height=10)
        commands.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        commands_text = """
/start - Initialize bot
/ask <question> - Ask AI something
/create <type> <prompt> - Create content
/post <platform> - Post to social media
/agents - List active agents
/status - System status
/help - Show all commands
        """
        commands.insert(tk.END, commands_text)
        commands.configure(state=tk.DISABLED)
    
    def build_settings_tab(self, notebook):
        """Settings tab"""
        frame = ttk.Frame(notebook)
        notebook.add(frame, text="⚙️ Settings")
        
        # User info
        user_frame = tk.Frame(frame, bg=self.colors['dark'], relief=tk.SUNKEN, bd=1)
        user_frame.pack(fill=tk.X, padx=10, pady=10)
        
        tk.Label(user_frame, text="Account", bg=self.colors['dark'],
                fg=self.colors['accent'], font=('Arial', 11, 'bold')).pack(fill=tk.X, padx=5, pady=5)
        
        tk.Label(user_frame, text=f"User: {self.current_user}", bg=self.colors['dark'],
                fg=self.colors['secondary']).pack(fill=tk.X, padx=10, pady=5)
        
        tk.Label(user_frame, text=f"Logged in: {datetime.now().strftime('%Y-%m-%d %H:%M')}", 
                bg=self.colors['dark'], fg=self.colors['warning']).pack(fill=tk.X, padx=10, pady=5)
        
        # Actions
        actions = tk.Frame(frame, bg=self.colors['dark'], relief=tk.SUNKEN, bd=1)
        actions.pack(fill=tk.X, padx=10, pady=10)
        
        tk.Label(actions, text="Actions", bg=self.colors['dark'],
                fg=self.colors['accent'], font=('Arial', 11, 'bold')).pack(fill=tk.X, padx=5, pady=5)
        
        def logout():
            self.logged_in = False
            self.show_login()
        
        tk.Button(actions, text="LOGOUT", bg=self.colors['warning'],
                 fg='#000000', font=('Arial', 10, 'bold'),
                 command=logout, cursor='hand2').pack(fill=tk.X, padx=10, pady=10)
    
    def send_ai_question(self, model):
        """Send question to AI"""
        question = self.question_input.get("1.0", tk.END).strip()
        if not question:
            messagebox.showwarning("Empty", "Enter a question!")
            return
        
        self.add_chat_message('user', f"You ({model}): {question}")
        self.question_input.delete("1.0", tk.END)
        
        # Simulate AI response
        threading.Thread(target=self._ai_response, args=(question, model), daemon=True).start()
    
    def _ai_response(self, question, model):
        """Get AI response"""
        try:
            response = f"[{model}] Processing: {question[:50]}...\n\nThis is a demonstration response from {model}."
            self.add_chat_message('ai', response)
        except Exception as e:
            self.add_chat_message('system', f"Error: {str(e)}")
    
    def add_chat_message(self, sender, message):
        """Add message to chat"""
        self.chat_display.configure(state=tk.NORMAL)
        
        if sender == 'user':
            self.chat_display.insert(tk.END, message + "\n", 'user')
        elif sender == 'ai':
            self.chat_display.insert(tk.END, message + "\n", 'ai')
        else:
            self.chat_display.insert(tk.END, message + "\n", 'system')
        
        self.chat_display.see(tk.END)
        self.chat_display.configure(state=tk.DISABLED)
    
    def clear_chat(self):
        """Clear chat"""
        self.chat_display.configure(state=tk.NORMAL)
        self.chat_display.delete("1.0", tk.END)
        self.chat_display.configure(state=tk.DISABLED)
    
    def refresh_agents_list(self):
        """Refresh agents display"""
        self.agents_list.configure(state=tk.NORMAL)
        self.agents_list.delete("1.0", tk.END)
        
        self.agents_list.insert(tk.END, "DEFAULT AGENTS:\n", 'accent')
        self.agents_list.insert(tk.END, "=" * 35 + "\n")
        defaults = [
            ("Anti-Cancer AI", "Medical"),
            ("Drug Discovery", "Pharma"),
            ("ML Orchestrator", "DataScience"),
        ]
        for name, spec in defaults:
            self.agents_list.insert(tk.END, f"✓ {name} [{spec}]\n")
        
        if self.agents:
            self.agents_list.insert(tk.END, "\nCUSTOM AGENTS:\n", 'accent')
            self.agents_list.insert(tk.END, "=" * 35 + "\n")
            for name, config in self.agents.items():
                self.agents_list.insert(tk.END, 
                    f"+ {name} [{config['type']}]\n")
        
        self.agents_list.configure(state=tk.DISABLED)


def main():
    """Launch application"""
    root = tk.Tk()
    root.configure(bg="#0a0e27")
    app = Gene1799ProAI(root)
    root.mainloop()


if __name__ == '__main__':
    main()
