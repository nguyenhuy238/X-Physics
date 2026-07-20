import { useState } from "react";
import { Eye, EyeOff, Atom, Mail, Lock } from "lucide-react";
import { motion } from "motion/react";

interface LoginProps {
  onLogin: () => void;
  onRegister: () => void;
}

export function Login({ onLogin, onRegister }: LoginProps) {
  const [showPass, setShowPass] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");

  const handleLogin = () => {
    if (!email || !password) {
      setError("Vui lòng nhập đầy đủ thông tin.");
      return;
    }
    setError("");
    onLogin();
  };

  return (
    <div className="h-full overflow-y-auto bg-background flex flex-col px-6 pt-14 pb-8">
      {/* Logo */}
      <motion.div
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="flex items-center gap-2 justify-center mb-8"
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
        <h2 className="text-foreground font-black text-2xl">Chào mừng trở lại! 👋</h2>
        <p className="text-muted-foreground mt-1 text-sm">Đăng nhập để tiếp tục học tập</p>
      </motion.div>

      <motion.div
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="mt-8 flex flex-col gap-4"
      >
        {/* Email */}
        <div>
          <label className="text-sm text-foreground font-semibold mb-1.5 block">Email</label>
          <div className="relative">
            <Mail size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="name@example.com"
              className="w-full pl-10 pr-4 py-3.5 bg-input-background rounded-xl border border-border text-foreground placeholder:text-muted-foreground/60 focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition"
            />
          </div>
        </div>

        {/* Password */}
        <div>
          <label className="text-sm text-foreground font-semibold mb-1.5 block">Mật khẩu</label>
          <div className="relative">
            <Lock size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <input
              type={showPass ? "text" : "password"}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Nhập mật khẩu"
              className="w-full pl-10 pr-12 py-3.5 bg-input-background rounded-xl border border-border text-foreground placeholder:text-muted-foreground/60 focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition"
            />
            <button
              onClick={() => setShowPass(!showPass)}
              className="absolute right-3.5 top-1/2 -translate-y-1/2 text-muted-foreground"
            >
              {showPass ? <EyeOff size={16} /> : <Eye size={16} />}
            </button>
          </div>
        </div>

        {error && (
          <p className="text-destructive text-xs font-medium bg-destructive/10 rounded-lg px-3 py-2">{error}</p>
        )}

        <div className="text-right">
          <button className="text-primary text-sm font-semibold">Quên mật khẩu?</button>
        </div>

        <button
          onClick={handleLogin}
          className="w-full py-4 bg-primary rounded-2xl text-white font-black text-base mt-1 active:scale-95 transition-transform shadow-lg shadow-primary/20"
        >
          Đăng nhập
        </button>

      </motion.div>

      <div className="mt-auto pt-6 text-center">
        <p className="text-muted-foreground text-sm">
          Chưa có tài khoản?{" "}
          <button onClick={onRegister} className="text-primary font-black">
            Đăng ký ngay
          </button>
        </p>
      </div>
    </div>
  );
}
