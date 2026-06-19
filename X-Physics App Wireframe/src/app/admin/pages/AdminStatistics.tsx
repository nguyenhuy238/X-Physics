import {
  AreaChart, Area, XAxis, YAxis, ResponsiveContainer, Tooltip,
  BarChart, Bar, Cell, PieChart, Pie, Legend,
} from "recharts";
import { activeUsersData, difficultLessonsData } from "../adminData";
import { TrendingUp, BookOpen, Users, Star } from "lucide-react";

const completionData = [
  { name: "Chương 1", value: 80, color: "#2563EB" },
  { name: "Chương 2", value: 50, color: "#7C3AED" },
  { name: "Chương 3", value: 17, color: "#F59E0B" },
  { name: "Chương 4", value: 0, color: "#94A3B8" },
];

const scoreDistribution = [
  { range: "0–4", count: 2, color: "#EF4444" },
  { range: "4–6", count: 5, color: "#F59E0B" },
  { range: "6–8", count: 12, color: "#2563EB" },
  { range: "8–10", count: 8, color: "#22C55E" },
];

const weeklyData = [
  { week: "Tuần 1", quizzes: 18, lessons: 24 },
  { week: "Tuần 2", quizzes: 25, lessons: 31 },
  { week: "Tuần 3", quizzes: 22, lessons: 28 },
  { week: "Tuần 4", quizzes: 35, lessons: 42 },
];

export function AdminStatistics() {
  return (
    <div className="flex-1 overflow-y-auto p-8 bg-[#F8FAFC]">
      {/* KPI row */}
      <div className="grid grid-cols-4 gap-5 mb-7">
        {[
          { label: "Tổng bài kiểm tra", value: "127", icon: BookOpen, trend: "+12%", color: "#2563EB", bg: "#DBEAFE" },
          { label: "Điểm trung bình", value: "7.6", icon: Star, trend: "+0.3", color: "#22C55E", bg: "#DCFCE7" },
          { label: "Người dùng hoạt động", value: "103", icon: Users, trend: "+18%", color: "#7C3AED", bg: "#EDE9FE" },
          { label: "Tỷ lệ hoàn thành", value: "48%", icon: TrendingUp, trend: "+5%", color: "#D97706", bg: "#FEF3C7" },
        ].map(({ label, value, icon: Icon, trend, color, bg }) => (
          <div key={label} className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm">
            <div className="flex items-start justify-between mb-3">
              <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{ backgroundColor: bg }}>
                <Icon size={18} style={{ color }} />
              </div>
              <span className="text-green-600 text-xs font-black bg-green-50 px-2 py-0.5 rounded-full">{trend}</span>
            </div>
            <p className="text-[#0F172A] font-black text-2xl">{value}</p>
            <p className="text-slate-500 text-xs font-medium mt-0.5">{label}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-3 gap-5 mb-5">
        {/* Weekly activity */}
        <div className="col-span-2 bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">
          <h3 className="text-[#0F172A] font-black text-base mb-1">Hoạt động theo tuần</h3>
          <p className="text-slate-400 text-xs mb-5">Số bài học và kiểm tra hoàn thành</p>
          <ResponsiveContainer width="100%" height={180}>
            <BarChart data={weeklyData} barGap={4}>
              <XAxis dataKey="week" tick={{ fontSize: 11, fontWeight: 700, fill: "#94A3B8" }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: "#94A3B8" }} axisLine={false} tickLine={false} width={28} />
              <Tooltip contentStyle={{ background: "#0F172A", border: "none", borderRadius: 12, color: "#fff", fontSize: 12 }} />
              <Bar dataKey="lessons" name="Bài học" fill="#DBEAFE" radius={[4, 4, 0, 0]} barSize={18} />
              <Bar dataKey="quizzes" name="Kiểm tra" fill="#2563EB" radius={[4, 4, 0, 0]} barSize={18} />
            </BarChart>
          </ResponsiveContainer>
          <div className="flex justify-center gap-5 mt-1">
            <div className="flex items-center gap-1.5"><div className="w-3 h-3 rounded bg-blue-100" /><span className="text-slate-500 text-xs font-medium">Bài học</span></div>
            <div className="flex items-center gap-1.5"><div className="w-3 h-3 rounded bg-primary" /><span className="text-slate-500 text-xs font-medium">Kiểm tra</span></div>
          </div>
        </div>

        {/* Score distribution */}
        <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">
          <h3 className="text-[#0F172A] font-black text-base mb-1">Phân bổ điểm số</h3>
          <p className="text-slate-400 text-xs mb-5">Tổng 27 học sinh</p>
          <div className="flex flex-col gap-3">
            {scoreDistribution.map(({ range, count, color }) => (
              <div key={range}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-slate-600 text-xs font-black">{range} điểm</span>
                  <span className="font-black text-xs" style={{ color }}>{count} hs</span>
                </div>
                <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
                  <div className="h-full rounded-full transition-all" style={{ width: `${(count / 27) * 100}%`, backgroundColor: color }} />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-5">
        {/* Chapter completion */}
        <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">
          <h3 className="text-[#0F172A] font-black text-base mb-5">Tỷ lệ hoàn thành chương</h3>
          <div className="flex flex-col gap-4">
            {completionData.map(({ name, value, color }) => (
              <div key={name}>
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-slate-700 text-sm font-semibold">{name}</span>
                  <span className="font-black text-sm" style={{ color }}>{value}%</span>
                </div>
                <div className="h-2.5 bg-slate-100 rounded-full overflow-hidden">
                  <div className="h-full rounded-full" style={{ width: `${value}%`, backgroundColor: color }} />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Difficult lessons bar */}
        <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">
          <h3 className="text-[#0F172A] font-black text-base mb-1">Bài học khó nhất</h3>
          <p className="text-slate-400 text-xs mb-5">Điểm trung bình thấp</p>
          <ResponsiveContainer width="100%" height={180}>
            <BarChart data={difficultLessonsData} layout="vertical" barSize={14}>
              <XAxis type="number" domain={[0, 10]} tick={{ fontSize: 11, fill: "#94A3B8" }} axisLine={false} tickLine={false} />
              <YAxis type="category" dataKey="name" tick={{ fontSize: 10, fontWeight: 700, fill: "#64748B" }} axisLine={false} tickLine={false} width={120} />
              <Tooltip contentStyle={{ background: "#0F172A", border: "none", borderRadius: 12, color: "#fff", fontSize: 12 }} />
              <Bar dataKey="avgScore" name="Điểm TB" radius={[0, 6, 6, 0]}>
                {difficultLessonsData.map((entry, i) => (
                  <Cell key={i} fill={entry.avgScore < 6 ? "#EF4444" : entry.avgScore < 7 ? "#F59E0B" : "#22C55E"} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
