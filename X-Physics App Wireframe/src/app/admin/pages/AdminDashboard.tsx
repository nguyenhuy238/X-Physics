import {
  AreaChart, Area, XAxis, YAxis, ResponsiveContainer, Tooltip, BarChart, Bar, Cell,
} from "recharts";
import { Users, BookOpen, FileText, HelpCircle, TrendingUp, Flame } from "lucide-react";
import { activeUsersData, difficultLessonsData, recentActivity } from "../adminData";

const activityIcons: Record<string, string> = {
  quiz: "📝",
  lesson: "📖",
  register: "🆕",
  download: "⬇️",
  badge: "🏅",
};

export function AdminDashboard() {
  const statCards = [
    { label: "Học sinh", value: "5", icon: Users, color: "#2563EB", bg: "#DBEAFE", change: "+2 tuần này" },
    { label: "Chương học", value: "5", icon: BookOpen, color: "#7C3AED", bg: "#EDE9FE", change: "4 đã xuất bản" },
    { label: "Bài học", value: "18", icon: FileText, color: "#059669", bg: "#D1FAE5", change: "15 đã xuất bản" },
    { label: "Câu hỏi", value: "42", icon: HelpCircle, color: "#D97706", bg: "#FEF3C7", change: "+8 tuần này" },
  ];

  return (
    <div className="flex-1 overflow-y-auto p-8 bg-[#F8FAFC]">
      {/* Stat cards */}
      <div className="grid grid-cols-4 gap-5 mb-7">
        {statCards.map(({ label, value, icon: Icon, color, bg, change }) => (
          <div key={label} className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm hover:shadow-md transition-shadow">
            <div className="flex items-start justify-between">
              <div>
                <p className="text-slate-500 text-xs font-semibold uppercase tracking-wide">{label}</p>
                <p className="text-[#0F172A] font-black text-3xl mt-1">{value}</p>
                <p className="text-slate-400 text-xs font-medium mt-1">{change}</p>
              </div>
              <div className="w-11 h-11 rounded-2xl flex items-center justify-center" style={{ backgroundColor: bg }}>
                <Icon size={20} style={{ color }} />
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Charts row */}
      <div className="grid grid-cols-3 gap-5 mb-7">
        {/* Active users area chart */}
        <div className="col-span-2 bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className="text-[#0F172A] font-black text-base">Người dùng hoạt động</h3>
              <p className="text-slate-400 text-xs font-medium mt-0.5">7 ngày gần nhất</p>
            </div>
            <div className="flex items-center gap-1.5 bg-green-50 rounded-full px-3 py-1.5">
              <TrendingUp size={13} className="text-green-600" />
              <span className="text-green-700 font-black text-xs">+18%</span>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={180}>
            <AreaChart data={activeUsersData}>
              <defs>
                <linearGradient id="colorUsers" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#2563EB" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#2563EB" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey="day" tick={{ fontSize: 12, fontWeight: 700, fill: "#94A3B8" }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: "#94A3B8" }} axisLine={false} tickLine={false} width={30} />
              <Tooltip
                contentStyle={{ background: "#0F172A", border: "none", borderRadius: 12, color: "#fff", fontSize: 12 }}
                cursor={{ stroke: "#2563EB", strokeWidth: 1, strokeDasharray: "4 4" }}
              />
              <Area type="monotone" dataKey="users" stroke="#2563EB" strokeWidth={2.5} fill="url(#colorUsers)" dot={{ fill: "#2563EB", r: 4 }} activeDot={{ r: 6 }} />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Difficult lessons */}
        <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">
          <h3 className="text-[#0F172A] font-black text-base mb-1">Bài học khó nhất</h3>
          <p className="text-slate-400 text-xs font-medium mb-5">Theo điểm trung bình</p>
          <ResponsiveContainer width="100%" height={180}>
            <BarChart data={difficultLessonsData} layout="vertical" barSize={14}>
              <XAxis type="number" domain={[0, 10]} hide />
              <YAxis type="category" dataKey="name" tick={{ fontSize: 10, fontWeight: 700, fill: "#64748B" }} axisLine={false} tickLine={false} width={110} />
              <Tooltip
                contentStyle={{ background: "#0F172A", border: "none", borderRadius: 12, color: "#fff", fontSize: 12 }}
              />
              <Bar dataKey="avgScore" radius={[0, 6, 6, 0]}>
                {difficultLessonsData.map((entry, i) => (
                  <Cell key={i} fill={entry.avgScore < 6 ? "#EF4444" : entry.avgScore < 7 ? "#F59E0B" : "#22C55E"} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Recent activity */}
      <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
          <h3 className="text-[#0F172A] font-black text-base">Hoạt động gần đây</h3>
          <button className="text-primary text-sm font-semibold hover:underline">Xem tất cả</button>
        </div>
        <div className="divide-y divide-slate-50">
          {recentActivity.map((item) => (
            <div key={item.id} className="flex items-center gap-4 px-6 py-3.5 hover:bg-slate-50/50 transition-colors">
              <div className="w-9 h-9 bg-slate-100 rounded-xl flex items-center justify-center text-lg shrink-0">
                {activityIcons[item.type]}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-[#0F172A] text-sm font-semibold">
                  <span className="text-primary">{item.user}</span> — {item.action}
                </p>
                <p className="text-slate-400 text-xs font-medium truncate">{item.detail}</p>
              </div>
              <span className="text-slate-400 text-xs font-medium shrink-0 flex items-center gap-1">
                <Flame size={11} className="text-orange-400" /> {item.time}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
