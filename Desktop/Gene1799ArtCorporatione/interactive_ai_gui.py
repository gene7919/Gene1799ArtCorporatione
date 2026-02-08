#!/usr/bin/env python3
"""
Gene1799 Interactive AI GUI
Advanced interface for Q&A, agent management, and server integration
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, simpledialog
import requests
import json
import threading
from datetime import datetime
from typing import Dict, List
import os
from pathlib import Path

# Render server URL
RENDER_SERVER = "https://gene1799-api.onrender.com"


class InteractiveAIGUI:
    """Advanced interactive AI GUI with chat and agent management"""
    
    def __init__(self, root):
        self.root = root
        self.root.title("Gene1799 AI Solutions - Interactive Interface")
        self.root.geometry("1200x800")
        self.root.configure(bg="#1e1e1e")
        
        # Configure style
        self.setup_styles()
        
        # Data
        self.chat_history = []
        self.custom_agents = {}
        self.server_status = "Checking..."
        
        # Build UI
        self.build_header()
        self.build_main_layout()
        self.build_footer()
        
        # Check server status
        self.check_server_status()
        
    def setup_styles(self):
        """Setup modern color scheme"""
        style = ttk.Style()
        style.theme_use('clam')
        
        # Define colors
        self.colors = {
            'bg': '#1e1e1e',
            'fg': '#ffffff',
            'accent': '#00d9ff',
            'success': '#00ff41',
            'warning': '#ffaa00',
            'error': '#ff5555',
            'dark': '#0d1117',
            'light': '#30373f'
        }
        
        # Configure styles
        style.configure('Header.TLabel', background='#0d0d0d', foreground='#00d9ff', 
                       font=('Arial', 12, 'bold'))
        style.configure('TLabel', background='#1e1e1e', foreground='#ffffff')
        style.configure('TButton', background='#30373f', foreground='#00d9ff')
    
    def build_header(self):
        """Build top header"""
        header = tk.Frame(self.root, bg='#0d0d0d', height=60)
        header.pack(fill=tk.X)
        
        # Title
        title = tk.Label(header, text="🤖 GENE1799 AI SOLUTIONS ENGINE",
                        bg='#0d0d0d', fg='#00d9ff', font=('Arial', 16, 'bold'))
        title.pack(side=tk.LEFT, padx=20, pady=10)
        
        # Server status
        self.status_label = tk.Label(header, text="Server: Checking...",
                                    bg='#0d0d0d', fg='#ffaa00', font=('Arial', 10))
        self.status_label.pack(side=tk.RIGHT, padx=20, pady=10)
    
    def build_main_layout(self):
        """Build main content area"""
        main = ttk.Frame(self.root)
        main.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create two main sections
        left_panel = ttk.Frame(main)
        left_panel.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(0, 5))
        
        right_panel = ttk.Frame(main)
        right_panel.pack(side=tk.RIGHT, fill=tk.BOTH, expand=False, width=350)
        
        # Left: Chat interface
        self.build_chat_interface(left_panel)
        
        # Right: Agent management
        self.build_agent_panel(right_panel)
    
    def build_chat_interface(self, parent):
        """Build Q&A chat interface"""
        # Title
        title = tk.Label(parent, text="💬 ASK ANYTHING",
                        bg='#1e1e1e', fg='#00d9ff', font=('Arial', 12, 'bold'))
        title.pack(fill=tk.X, pady=(0, 10))
        
        # Chat display
        chat_frame = tk.Frame(parent, bg='#0d1117', relief=tk.SUNKEN, bd=1)
        chat_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        self.chat_display = scrolledtext.ScrolledText(
            chat_frame, bg='#0d1117', fg='#ffffff', 
            font=('Courier', 9), wrap=tk.WORD,
            state=tk.DISABLED
        )
        self.chat_display.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        # Configure tags for styling
        self.chat_display.tag_config('user', foreground='#00d9ff', font=('Courier', 9, 'bold'))
        self.chat_display.tag_config('ai', foreground='#00ff41', font=('Courier', 9))
        self.chat_display.tag_config('system', foreground='#ffaa00', font=('Courier', 8, 'italic'))
        
        # Input area
        input_frame = tk.Frame(parent, bg='#1e1e1e')
        input_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.question_input = tk.Text(input_frame, height=3, bg='#30373f', 
                                     fg='#ffffff', font=('Courier', 10),
                                     insertbackground='#00d9ff')
        self.question_input.pack(fill=tk.BOTH, expand=True, padx=(0, 5))
        
        # Send button
        send_btn = tk.Button(input_frame, text="SEND QUESTION",
                           bg='#00d9ff', fg='#000000', font=('Arial', 10, 'bold'),
                           command=self.send_question, cursor='hand2')
        send_btn.pack(side=tk.RIGHT, fill=tk.X)
    
    def build_agent_panel(self, parent):
        """Build agent management panel"""
        # Title
        title = tk.Label(parent, text="🤖 AGENTS",
                        bg='#1e1e1e', fg='#00d9ff', font=('Arial', 11, 'bold'))
        title.pack(fill=tk.X, pady=(0, 10))
        
        # Agents list
        agents_frame = tk.Frame(parent, bg='#0d1117', relief=tk.SUNKEN, bd=1)
        agents_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        self.agents_display = scrolledtext.ScrolledText(
            agents_frame, bg='#0d1117', fg='#00ff41',
            font=('Courier', 8), wrap=tk.WORD, state=tk.DISABLED, height=15
        )
        self.agents_display.pack(fill=tk.BOTH, expand=True, padx=3, pady=3)
        
        # Add agent section
        add_agent_frame = tk.Frame(parent, bg='#1e1e1e')
        add_agent_frame.pack(fill=tk.X, pady=(0, 10))
        
        tk.Label(add_agent_frame, text="New Agent Name:",
                bg='#1e1e1e', fg='#ffffff', font=('Arial', 9)).pack(fill=tk.X)
        
        self.agent_name_input = tk.Entry(add_agent_frame, bg='#30373f',
                                        fg='#ffffff', insertbackground='#00d9ff')
        self.agent_name_input.pack(fill=tk.X, pady=(0, 5))
        
        tk.Label(add_agent_frame, text="Specialization:",
                bg='#1e1e1e', fg='#ffffff', font=('Arial', 9)).pack(fill=tk.X)
        
        specializations = ['Medical', 'Pharma', 'Data Science', 'Healthcare', 'Custom']
        self.spec_var = tk.StringVar(value='Medical')
        spec_menu = ttk.Combobox(add_agent_frame, textvariable=self.spec_var,
                                values=specializations, state='readonly')
        spec_menu.pack(fill=tk.X, pady=(0, 10))
        
        # Buttons
        btn_frame = tk.Frame(add_agent_frame, bg='#1e1e1e')
        btn_frame.pack(fill=tk.X)
        
        add_btn = tk.Button(btn_frame, text="+ ADD",
                          bg='#00ff41', fg='#000000', font=('Arial', 9, 'bold'),
                          command=self.add_agent, cursor='hand2')
        add_btn.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 2))
        
        del_btn = tk.Button(btn_frame, text="- DELETE",
                          bg='#ff5555', fg='#ffffff', font=('Arial', 9, 'bold'),
                          command=self.delete_agent, cursor='hand2')
        del_btn.pack(side=tk.RIGHT, fill=tk.X, expand=True)
        
        # Refresh agents list
        self.refresh_agents_display()
    
    def build_footer(self):
        """Build bottom footer"""
        footer = tk.Frame(self.root, bg='#0d0d0d', height=40)
        footer.pack(fill=tk.X)
        
        # Status and buttons
        info_btn = tk.Button(footer, text="📊 System Info",
                           bg='#30373f', fg='#00d9ff', font=('Arial', 9),
                           command=self.show_system_info, cursor='hand2')
        info_btn.pack(side=tk.LEFT, padx=5, pady=5)
        
        render_btn = tk.Button(footer, text="☁️ Render Server",
                             bg='#30373f', fg='#00d9ff', font=('Arial', 9),
                             command=self.connect_render, cursor='hand2')
        render_btn.pack(side=tk.LEFT, padx=2, pady=5)
        
        clear_btn = tk.Button(footer, text="🗑️ Clear Chat",
                            bg='#30373f', fg='#ffaa00', font=('Arial', 9),
                            command=self.clear_chat, cursor='hand2')
        clear_btn.pack(side=tk.LEFT, padx=2, pady=5)
        
        self.footer_info = tk.Label(footer, text="Ready",
                                   bg='#0d0d0d', fg='#00ff41', font=('Arial', 9))
        self.footer_info.pack(side=tk.RIGHT, padx=10, pady=5)
    
    def send_question(self):
        """Send user question to AI agents"""
        question = self.question_input.get("1.0", tk.END).strip()
        
        if not question:
            messagebox.showwarning("Empty Input", "Please type a question!")
            return
        
        # Add to chat
        self.add_chat_message("user", f"You: {question}")
        self.question_input.delete("1.0", tk.END)
        
        # Process in thread
        threading.Thread(target=self.process_question, args=(question,), daemon=True).start()
    
    def process_question(self, question: str):
        """Process question through agents"""
        try:
            # Simulate AI processing (in production: call actual agents)
            response = self.get_ai_response(question)
            self.add_chat_message("ai", f"AI: {response}")
            self.update_footer(f"Processed - {datetime.now().strftime('%H:%M:%S')}")
            
        except Exception as e:
            self.add_chat_message("system", f"Error: {str(e)}")
    
    def get_ai_response(self, question: str) -> str:
        """Get response from AI (placeholder)"""
        # Keywords-based responses for demo
        keywords = {
            'medical': 'I can help with medical analysis using our Anti-Cancer AI Engine.',
            'pharma': 'Drug discovery tasks are handled by our pharmaceutical agents.',
            'data': 'Data science operations are coordinated by specialized ML agents.',
            'agent': f'I manage {len(self.custom_agents) + 4} agents. Try asking about specializations.',
            'status': 'All systems operational. GPU RTX 4070 at full capacity.',
        }
        
        question_lower = question.lower()
        for key, response in keywords.items():
            if key in question_lower:
                return response
        
        return f"Processing: {question[:50]}... I can analyze this with our {len(self.custom_agents) + 4} active agents."
    
    def add_agent(self):
        """Add new specialized agent"""
        name = self.agent_name_input.get().strip()
        spec = self.spec_var.get()
        
        if not name:
            messagebox.showwarning("Empty Name", "Enter agent name!")
            return
        
        self.custom_agents[name] = {
            'name': name,
            'specialization': spec,
            'created': datetime.now().isoformat(),
            'status': 'active'
        }
        
        self.agent_name_input.delete(0, tk.END)
        self.refresh_agents_display()
        self.add_chat_message("system", f"✓ Agent '{name}' added ({spec})")
    
    def delete_agent(self):
        """Delete selected agent"""
        if not self.custom_agents:
            messagebox.showinfo("No Agents", "No custom agents to delete!")
            return
        
        # Get first agent for demo
        agent_name = list(self.custom_agents.keys())[0]
        del self.custom_agents[agent_name]
        self.refresh_agents_display()
        self.add_chat_message("system", f"✗ Agent '{agent_name}' removed")
    
    def refresh_agents_display(self):
        """Update agents list display"""
        self.agents_display.configure(state=tk.NORMAL)
        self.agents_display.delete("1.0", tk.END)
        
        # Built-in agents
        default_agents = [
            ('Anti-Cancer Engine', 'Medical', '✓'),
            ('Drug Discovery', 'Pharma', '✓'),
            ('Healthcare System', 'Healthcare', '✓'),
            ('ML Orchestrator', 'Data Science', '✓'),
        ]
        
        self.agents_display.insert(tk.END, "DEFAULT AGENTS:\n", 'system')
        self.agents_display.insert(tk.END, "=" * 30 + "\n")
        
        for name, spec, status in default_agents:
            self.agents_display.insert(tk.END, f"{status} {name}\n")
            self.agents_display.insert(tk.END, f"   [{spec}]\n")
        
        # Custom agents
        if self.custom_agents:
            self.agents_display.insert(tk.END, "\n\nCUSTOM AGENTS:\n", 'system')
            self.agents_display.insert(tk.END, "=" * 30 + "\n")
            
            for agent_name, agent_data in self.custom_agents.items():
                self.agents_display.insert(tk.END, f"+ {agent_data['name']}\n")
                self.agents_display.insert(tk.END, 
                    f"   [{agent_data['specialization']}]\n")
        
        self.agents_display.configure(state=tk.DISABLED)
    
    def add_chat_message(self, sender: str, message: str):
        """Add message to chat display"""
        self.chat_display.configure(state=tk.NORMAL)
        
        if sender == 'user':
            self.chat_display.insert(tk.END, message + "\n", 'user')
        elif sender == 'ai':
            self.chat_display.insert(tk.END, message + "\n", 'ai')
        else:  # system
            self.chat_display.insert(tk.END, message + "\n", 'system')
        
        self.chat_display.see(tk.END)
        self.chat_display.configure(state=tk.DISABLED)
        self.chat_history.append({'sender': sender, 'message': message, 'time': datetime.now()})
    
    def clear_chat(self):
        """Clear chat history"""
        self.chat_display.configure(state=tk.NORMAL)
        self.chat_display.delete("1.0", tk.END)
        self.chat_display.configure(state=tk.DISABLED)
        self.chat_history.clear()
    
    def check_server_status(self):
        """Check Render server status"""
        threading.Thread(target=self._check_server, daemon=True).start()
    
    def _check_server(self):
        """Background server check"""
        try:
            response = requests.get(f"{RENDER_SERVER}/health", timeout=3)
            if response.status_code == 200:
                self.status_label.configure(text="✓ Server: Online", fg='#00ff41')
                self.server_status = "Online"
            else:
                self.status_label.configure(text="⚠ Server: Slow", fg='#ffaa00')
                self.server_status = "Slow"
        except:
            self.status_label.configure(text="✗ Server: Offline", fg='#ff5555')
            self.server_status = "Offline"
    
    def connect_render(self):
        """Connect to Render server"""
        messagebox.showinfo("Render Server",
            f"Server Status: {self.server_status}\n\n"
            "Connected to: api.onrender.com\n"
            "Services: Backend API, Frontend Web\n\n"
            "Click to open dashboard")
    
    def show_system_info(self):
        """Show system information"""
        info = f"""
╔════════════════════════════════════════╗
║    GENE1799 SYSTEM INFORMATION         ║
╠════════════════════════════════════════╣
║                                        ║
║  Total Agents: {len(self.custom_agents) + 4}
║  Server Status: {self.server_status}
║  Chat Messages: {len(self.chat_history)}
║  GPU: RTX 4070 (Available)
║  Status: Operational                   ║
║                                        ║
║  SERVICES:                             ║
║  ✓ Backend API (Port 3000)             ║
║  ✓ Frontend Web (Port 5173)            ║
║  ✓ AI Agents (Port 8000)               ║
║  ✓ GPU Monitor (Active)                ║
║                                        ║
╚════════════════════════════════════════╝
        """
        messagebox.showinfo("System Info", info)
    
    def update_footer(self, message: str):
        """Update footer information"""
        self.footer_info.configure(text=message)


def main():
    """Launch application"""
    root = tk.Tk()
    app = InteractiveAIGUI(root)
    
    # Try to set icon (if available)
    try:
        icon_path = Path.cwd() / "gene1799_icon.ico"
        if icon_path.exists():
            root.iconbitmap(icon_path)
    except:
        pass
    
    root.mainloop()


if __name__ == '__main__':
    main()
