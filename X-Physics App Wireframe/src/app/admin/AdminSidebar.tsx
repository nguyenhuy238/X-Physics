import {
  LayoutDashboard, BookOpen, FileText, HelpCircle, Users, BarChart2, Atom, ChevronRight, LogOut,
} from "lucide-react";

export type AdminPage = "dashboard" | "chapters" | "lessons" | "questions" | "students" | "statistics";

const navItems: { key: AdminPage; icon: typeof LayoutDashboard; label: string }[] = [
  { key: "dashboard", icon: LayoutDashboard, label: "Dashboard" },
  { key: "chapters", icon: BookOpen, label: "Chương học" },
  { key: "lessons", icon: FileText, label: "Bài học" },
  { key: "questions", icon: HelpCircle, label: "Câu hỏi" },
  { key: "students", icon: Users, label: "Học sinh" },
  { key: "statistics", icon: BarChart2, label: "Thống kê" },
];

interface AdminSidebarProps {
  active: AdminPage;
  onNavigate: (page: AdminPage) => void;
  onExit: () => void;
}

export function AdminSidebar({ active, onNavigate, onExit }: AdminSidebarProps) {
  return (
    <aside className="w-60 bg-[#0F172A] flex flex-col h-full shrink-0">
      {/* Logo */}
      <div className="flex items-center gap-3 px-6 py-5 border-b border-white/5">
        <div className="w-9 h-9 bg-primary rounded-xl flex items-center justify-center shrink-0">
          <Atom size={18} className="text-white" />
        </div>
        <div>
          <p className="text-white font-black text-sm leading-none">X-Physics</p>
          <p className="text-slate-400 text-[10px] font-medium mt-0.5">Admin Panel</p>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 flex flex-col gap-1 overflow-y-auto">
        <p className="text-slate-500 text-[10px] font-black uppercase tracking-widest px-3 mb-2">Quản lý nội dung</p>
        {navItems.map(({ key, icon: Icon, label }) => {
          const isActive = active === key;
          return (
            <button
              key={key}
              onClick={() => onNavigate(key)}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-left w-full transition-all group ${
                isActive ? "bg-primary text-white" : "text-slate-400 hover:bg-white/5 hover:text-white"
              }`}
            >
              <Icon size={17} strokeWidth={isActive ? 2.5 : 1.8} />
              <span className="text-sm font-semibold flex-1">{label}</span>
              {isActive && <ChevronRight size={14} className="opacity-60" />}
            </button>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="px-3 pb-5 border-t border-white/5 pt-3">
        <div className="flex items-center gap-3 px-3 py-2.5 mb-1">
          <div className="w-8 h-8 bg-secondary rounded-full flex items-center justify-center text-sm shrink-0">👨‍💼</div>
          <div className="min-w-0">
            <p className="text-white text-xs font-black truncate">Admin User</p>
            <p className="text-slate-500 text-[10px] truncate">admin@xphysics.edu.vn</p>
          </div>
        </div>
        <button
          onClick={onExit}
          className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-left w-full text-slate-400 hover:bg-white/5 hover:text-red-400 transition-all"
        >
          <LogOut size={17} strokeWidth={1.8} />
          <span className="text-sm font-semibold">Thoát Admin</span>
        </button>
      </div>
    </aside>
  );
}
