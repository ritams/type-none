"use client";

import { motion } from "framer-motion";
import { Mic, Command, Terminal, Cpu, Shield, Zap, Check, ArrowRight, Github } from "lucide-react";
import { Button } from "@/components/ui/button";
import Link from "next/link";

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col items-center bg-background selection:bg-primary selection:text-primary-foreground overflow-x-hidden">

      {/* Navbar */}
      <nav className="fixed top-0 w-full z-50 bg-background/80 backdrop-blur-md border-b border-border/40">
        <div className="container mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2 font-mono font-bold text-lg tracking-tighter">
            <div className="w-5 h-5 bg-primary text-primary-foreground flex items-center justify-center rounded-sm">
              <span className="text-xs">&gt;</span>
            </div>
            type(none)
          </div>
          <div className="flex items-center gap-6 text-sm font-medium">
            <Link href="#features" className="text-muted-foreground hover:text-foreground transition-colors">Features</Link>
            <Link href="https://github.com/ritam/type-none" target="_blank" className="text-muted-foreground hover:text-foreground transition-colors flex items-center gap-1">
              <Github size={16} /> GitHub
            </Link>
            <Button size="sm" asChild>
              <Link href="https://github.com/ritam/type-none/releases/latest">Download</Link>
            </Button>
          </div>
        </div>
      </nav>

      <main className="flex-1 w-full pt-32 pb-20">

        {/* Hero Section */}
        <section className="container mx-auto px-6 mb-24 flex flex-col items-center text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-secondary/50 border border-border text-xs font-mono text-muted-foreground mb-8"
          >
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
            </span>
            v1.0.0 Stable Release
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="text-5xl md:text-7xl font-bold tracking-tight mb-6 max-w-4xl"
          >
            Don't type. <br />
            <span className="text-muted-foreground">Just speak.</span>
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="text-lg md:text-xl text-muted-foreground max-w-2xl mb-10 leading-relaxed"
          >
            The open-source, local-first voice-to-text engine for macOS.
            <br />
            Transforms speech into polished prose in <span className="text-foreground font-semibold">O(1)</span> time.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.3 }}
            className="flex flex-col sm:flex-row items-center gap-4"
          >
            <Button size="lg" className="h-12 px-8 text-base">
              Download for macOS
              <ArrowRight className="ml-2 h-4 w-4" />
            </Button>
            <Button size="lg" variant="secondary" className="h-12 px-8 text-base font-mono">
              brew install type-none
              <span className="ml-2 text-muted-foreground opacity-50"># soon</span>
            </Button>
          </motion.div>

          {/* Visual: Terminal Window / Code Block */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.7, delay: 0.4 }}
            className="mt-20 w-full max-w-3xl relative group"
          >
            <div className="absolute -inset-1 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg blur opacity-20 group-hover:opacity-30 transition duration-1000 group-hover:duration-200"></div>
            <div className="relative rounded-lg border border-border bg-card shadow-2xl overflow-hidden">
              <div className="flex items-center px-4 py-2 border-b border-border bg-muted/30">
                <div className="flex gap-2">
                  <div className="w-3 h-3 rounded-full bg-red-500/20 border border-red-500/50"></div>
                  <div className="w-3 h-3 rounded-full bg-yellow-500/20 border border-yellow-500/50"></div>
                  <div className="w-3 h-3 rounded-full bg-green-500/20 border border-green-500/50"></div>
                </div>
                <div className="ml-4 text-xs font-mono text-muted-foreground">app.tsx — type(none)</div>
              </div>
              <div className="p-6 font-mono text-sm md:text-base overflow-x-auto">
                <div className="text-muted-foreground mb-4 select-none">
                        // ⌥ + Space to activate
                </div>
                <div>
                  <span className="text-purple-400">const</span> <span className="text-blue-400">transcribe</span> = <span className="text-purple-400">async</span> (audio: <span className="text-yellow-400">AudioBuffer</span>) <span className="text-purple-400">=&gt;</span> {"{"}
                </div>
                <div className="pl-4">
                  <span className="text-muted-foreground">// 100% local processing with Whisper</span>
                </div>
                <div className="pl-4">
                  <span className="text-purple-400">const</span> text = <span className="text-purple-400">await</span> whisper.<span className="text-blue-400">decode</span>(audio);
                </div>
                <div className="pl-4">
                  <span className="text-purple-400">return</span> text.<span className="text-blue-400">format</span>({"{"} <span className="text-blue-400">style</span>: <span className="text-green-400">"polished"</span> {"}"});
                </div>
                <div>{"}"}</div>
              </div>
            </div>
          </motion.div>
        </section>

        {/* Features Grid */}
        <section id="features" className="container mx-auto px-6 py-24 border-t border-border">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <FeatureCard
              icon={<Shield className="w-6 h-6" />}
              title="Localhost Only"
              description="Zero network requests. Your voice data never leaves your machine. Powered by whisper.cpp running on CPU/GPU."
            />
            <FeatureCard
              icon={<Zap className="w-6 h-6" />}
              title="Latency < 200ms"
              description="Optimized for Apple Silicon. Transcription happens in real-time as you speak, faster than human typing speed."
            />
            <FeatureCard
              icon={<Command className="w-6 h-6" />}
              title="Global Scope"
              description="Bind to Option+Space. Works in VS Code, Terminal, Slack, or any input field in the OS."
            />
          </div>
        </section>

        {/* Tech Stack / "Nerdy" details */}
        <section className="container mx-auto px-6 py-24">
          <h2 className="text-3xl font-bold mb-12 text-center">Built for Power Users</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 max-w-4xl mx-auto">
            <div className="p-6 rounded-lg bg-secondary/20 border border-border">
              <h3 className="font-mono text-lg mb-2 flex items-center gap-2">
                <Cpu size={20} /> Neural Engine
              </h3>
              <p className="text-muted-foreground text-sm">
                Directly taps into the Neural Engine on M1/M2/M3 chips for efficient matrix multiplication.
              </p>
            </div>
            <div className="p-6 rounded-lg bg-secondary/20 border border-border">
              <h3 className="font-mono text-lg mb-2 flex items-center gap-2">
                <Terminal size={20} /> CLI Friendly
              </h3>
              <p className="text-muted-foreground text-sm">
                Pipe output to stdout or clipboard. chainable with other unix tools (coming soon).
              </p>
            </div>
          </div>
        </section>

      </main>

      <footer className="border-t border-border py-12 bg-muted/20">
        <div className="container mx-auto px-6 flex flex-col md:flex-row justify-between items-center gap-4">
          <div className="text-sm text-muted-foreground">
            &copy; 2026 TypeNone. Open Source (MIT).
          </div>
          <div className="flex gap-6">
            <Link href="#" className="text-muted-foreground hover:text-foreground">Docs</Link>
            <Link href="#" className="text-muted-foreground hover:text-foreground">Privacy</Link>
            <Link href="https://github.com/ritam/type-none" className="text-muted-foreground hover:text-foreground">GitHub</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}

function FeatureCard({ icon, title, description }: { icon: React.ReactNode, title: string, description: string }) {
  return (
    <motion.div
      whileHover={{ y: -5 }}
      className="p-6 rounded-xl border border-border bg-card hover:bg-muted/50 transition-colors"
    >
      <div className="w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center text-primary mb-4">
        {icon}
      </div>
      <h3 className="text-xl font-semibold mb-2">{title}</h3>
      <p className="text-muted-foreground leading-relaxed">
        {description}
      </p>
    </motion.div>
  )
}
