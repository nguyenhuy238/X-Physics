import { useState } from "react";
import { Eye, EyeOff, Atom, Mail, Lock, User } from "lucide-react";
import { motion } from "motion/react";

interface RegisterProps {
  onRegister: () => void;
  onLogin: () => void;
}

export function Register({ onRegister, onLogin }: RegisterProps) {
  const [showPass, setShowPass] = useState(false);

  return (
    <div className="h-full overflow-y-auto bg-background flex flex-col px-6 pt-12 pb-8">
      <motion.div
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="flex items-center gap-2 justify-center mb-6"
      >
        <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
          <Atom size={20} className="text-white" />
        </div>
        <span className="font-black text-xl text-foreground">X-Physics</span>
      </motion.div>

      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.1 }}
      >
        <h2 className="text-foreground font-black text-2xl">Tạo tài khoản học tập 🎓</h2>
        <p className="text-muted-foreground mt-1 text-sm">Miễn phí hoàn toàn, học ngay hôm nay!</p>
      </motion.div>

      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="mt-6 flex flex-col gap-3.5"
      >
        <div>
          <label className="text-sm text-foreground font-semibold mb-1.5 block">Họ và tên</label>
          <div className="relative">
            <User size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <input placeholder="Nguyễn Văn Nam" className="w-full pl-10 pr-4 py-3.5 bg-input-background rounded-xl border border-border text-foreground placeholder:text-muted-foreground/60 focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition" />
          </div>
        </div>

        <div>
          <label className="text-sm text-foreground font-semibold mb-1.5 block">Email</label>
          <div className="relative">
            <Mail size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <input type="email" placeholder="name@example.com" className="w-full pl-10 pr-4 py-3.5 bg-input-background rounded-xl border border-border text-foreground placeholder:text-muted-foreground/60 focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition" />
          </div>
        </div>

        <div>
          <label className="text-sm text-foreground font-semibold mb-1.5 block">Mật khẩu</label>
          <div className="relative">
            <Lock size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <input type={showPass ? "text" : "password"} placeholder="Ít nhất 6 ký tự" className="w-full pl-10 pr-12 py-3.5 bg-input-background rounded-xl border border-border text-foreground placeholder:text-muted-foreground/60 focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition" />
            <button onClick={() => setShowPass(!showPass)} className="absolute right-3.5 top-1/2 -translate-y-1/2 text-muted-foreground">
              {showPass ? <EyeOff size={16} /> : <Eye size={16} />}
            </button>
          </div>
        </div>

        <div>
          <label className="text-sm text-foreground font-semibold mb-1.5 block">Xác nhận mật khẩu</label>
          <div className="relative">
            <Lock size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <input type="password" placeholder="Nhập lại mật khẩu" className="w-full pl-10 pr-4 py-3.5 bg-input-background rounded-xl border border-border text-foreground placeholder:text-muted-foreground/60 focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition" />
          </div>
        </div>

        <button
          onClick={onRegister}
          className="w-full py-4 bg-primary rounded-2xl text-white font-black text-base mt-1 active:scale-95 transition-transform shadow-lg shadow-primary/20"
        >
          Đăng ký
        </button>

        <div className="flex items-center gap-3">
          <div className="flex-1 h-px bg-border" />
          <span className="text-muted-foreground text-xs font-medium">hoặc</span>
          <div className="flex-1 h-px bg-border" />
        </div>

        <button className="w-full py-3.5 bg-card rounded-2xl border border-border font-semibold text-sm text-foreground flex items-center justify-center gap-2 active:scale-95 transition-transform">
          <span>🌐</span> Đăng ký với Google
        </button>
      </motion.div>

      <div className="mt-auto pt-5 text-center">
        <p className="text-muted-foreground text-sm">
          Đã có tài khoản?{" "}
          <button onClick={onLogin} className="text-primary font-black">
            Đăng nhập
          </button>
        </p>
      </div>
    </div>
  );
}
