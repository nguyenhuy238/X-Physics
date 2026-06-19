import { Search, Bell } from "lucide-react";

interface AdminHeaderProps {
  title: string;
  subtitle?: string;
}

export function AdminHeader({ title, subtitle }: AdminHeaderProps) {
  return (
    <header className="h-16 bg-white border-b border-slate-100 flex items-center px-8 gap-4 shrink-0 shadow-sm">
      <div className="flex-1">
        <h1 className="text-[#0F172A] font-black text-lg leading-none">{title}</h1>
        {subtitle && <p className="text-slate-500 text-xs font-medium mt-0.5">{subtitle}</p>}
      </div>
      <div className="flex items-center gap-3">
        <div className="relative">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            placeholder="Tìm kiếm..."
            className="pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-700 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary w-60 transition"
          />
        </div>
        <button className="relative w-9 h-9 bg-slate-50 border border-slate-200 rounded-xl flex items-center justify-center hover:bg-slate-100 transition">
          <Bell size={16} className="text-slate-600" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full border border-white" />
        </button>
        <div className="w-9 h-9 bg-primary rounded-xl flex items-center justify-center text-sm shrink-0">👨‍💼</div>
      </div>
    </header>
  );
}
