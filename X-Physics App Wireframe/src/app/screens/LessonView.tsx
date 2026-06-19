import { useState } from "react";
import { ArrowLeft, Bookmark, Download, ChevronRight, FlaskConical } from "lucide-react";
import { motion } from "motion/react";

interface LessonViewProps {
  lesson: { id: number; title: string; icon: string; duration: number };
  onBack: () => void;
  onQuiz: () => void;
}

function FormulaLab() {
  const [v, setV] = useState(5);
  const [t, setT] = useState(10);
  const s = v * t;

  return (
    <div className="bg-gradient-to-br from-primary/5 to-blue-50 rounded-2xl p-4 border border-primary/15">
      <div className="flex items-center gap-2 mb-3">
        <div className="w-7 h-7 bg-primary/10 rounded-lg flex items-center justify-center">
          <FlaskConical size={14} className="text-primary" />
        </div>
        <span className="text-foreground font-black text-sm">Phòng thí nghiệm bỏ túi</span>
      </div>

      <div className="bg-card rounded-xl p-3 mb-3 text-center border border-border">
        <p className="text-muted-foreground text-xs font-medium mb-1">Công thức</p>
        <p className="text-primary font-black text-xl">s = v × t</p>
      </div>

      {/* Sliders */}
      <div className="flex flex-col gap-3">
        <div>
          <div className="flex justify-between items-center mb-1.5">
            <span className="text-xs font-semibold text-muted-foreground">Vận tốc (v)</span>
            <span className="text-primary font-black text-sm">{v} m/s</span>
          </div>
          <input
            type="range"
            min={1}
            max={20}
            value={v}
            onChange={(e) => setV(Number(e.target.value))}
            className="w-full accent-primary h-1.5 rounded-full"
          />
          <div className="flex justify-between text-[10px] text-muted-foreground mt-0.5">
            <span>1</span><span>20 m/s</span>
          </div>
        </div>

        <div>
          <div className="flex justify-between items-center mb-1.5">
            <span className="text-xs font-semibold text-muted-foreground">Thời gian (t)</span>
            <span className="text-primary font-black text-sm">{t} s</span>
          </div>
          <input
            type="range"
            min={1}
            max={60}
            value={t}
            onChange={(e) => setT(Number(e.target.value))}
            className="w-full accent-primary h-1.5 rounded-full"
          />
          <div className="flex justify-between text-[10px] text-muted-foreground mt-0.5">
            <span>1</span><span>60 s</span>
          </div>
        </div>
      </div>

      {/* Result */}
      <motion.div
        key={s}
        initial={{ scale: 0.95 }}
        animate={{ scale: 1 }}
        className="mt-3 bg-secondary/20 rounded-xl p-3 text-center border border-secondary/30"
      >
        <p className="text-xs font-medium text-muted-foreground">Quãng đường</p>
        <p className="text-2xl font-black text-foreground mt-0.5">{s} <span className="text-base text-muted-foreground font-semibold">m</span></p>
        <p className="text-xs text-muted-foreground mt-1">s = {v} × {t} = {s} m</p>
      </motion.div>

      <p className="text-[11px] text-muted-foreground mt-2 text-center">
        💡 Thử thay đổi giá trị để thấy sự thay đổi của quãng đường
      </p>
    </div>
  );
}

export function LessonView({ lesson, onBack, onQuiz }: LessonViewProps) {
  const progress = 0.6;

  return (
    <div className="h-full flex flex-col bg-background">
      {/* AppBar */}
      <div className="bg-card border-b border-border pt-12 pb-3 px-5">
        <div className="flex items-center gap-3">
          <button onClick={onBack} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-muted active:scale-90 transition">
            <ArrowLeft size={18} className="text-foreground" />
          </button>
          <div className="flex-1 min-w-0">
            <p className="text-[10px] text-muted-foreground font-medium uppercase tracking-wide">Bài học</p>
            <h1 className="text-foreground font-black text-base truncate">{lesson.title}</h1>
          </div>
          <button className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-muted">
            <Download size={16} className="text-muted-foreground" />
          </button>
          <button className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-muted">
            <Bookmark size={16} className="text-muted-foreground" />
          </button>
        </div>
        {/* Progress bar */}
        <div className="mt-2 h-1 bg-muted rounded-full overflow-hidden">
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${progress * 100}%` }}
            transition={{ duration: 0.8 }}
            className="h-full bg-primary rounded-full"
          />
        </div>
        <p className="text-[10px] text-muted-foreground mt-1">{Math.round(progress * 100)}% hoàn thành</p>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-5 pt-4 pb-24 scrollbar-hide flex flex-col gap-4">
        {/* Theory card */}
        <div className="bg-card rounded-2xl p-4 border border-border shadow-sm">
          <h2 className="text-foreground font-black text-base mb-2">Chuyển động đều là gì?</h2>
          <p className="text-muted-foreground text-sm leading-relaxed">
            Chuyển động đều là chuyển động trong đó vật đi được những quãng đường bằng nhau trong những khoảng thời gian bằng nhau bất kỳ.
          </p>
        </div>

        {/* Formula highlight */}
        <div className="bg-primary rounded-2xl p-4 shadow-lg shadow-primary/20">
          <p className="text-blue-200 text-xs font-medium mb-2">Công thức cốt lõi</p>
          <div className="flex items-baseline gap-2">
            <span className="text-white font-black text-3xl">s = v × t</span>
          </div>
          <div className="mt-3 flex gap-4">
            {[
              { sym: "s", label: "Quãng đường (m)" },
              { sym: "v", label: "Vận tốc (m/s)" },
              { sym: "t", label: "Thời gian (s)" },
            ].map(({ sym, label }) => (
              <div key={sym}>
                <span className="text-secondary font-black text-sm">{sym}</span>
                <p className="text-blue-200 text-[10px] font-medium">{label}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Example */}
        <div className="bg-card rounded-2xl p-4 border border-border shadow-sm">
          <div className="flex items-center gap-2 mb-2">
            <span className="w-5 h-5 bg-secondary/20 rounded-md flex items-center justify-center text-xs">📐</span>
            <h3 className="text-foreground font-black text-sm">Ví dụ minh họa</h3>
          </div>
          <p className="text-muted-foreground text-sm leading-relaxed">
            Một xe ô tô chuyển động đều với vận tốc <span className="text-primary font-black">v = 60 km/h</span> trong thời gian <span className="text-primary font-black">t = 2 giờ</span>. Quãng đường xe đi được là:
          </p>
          <div className="mt-2 bg-muted rounded-xl p-3 text-center">
            <p className="text-foreground font-black text-base">s = 60 × 2 = <span className="text-primary">120 km</span></p>
          </div>
        </div>

        {/* Interactive lab */}
        <FormulaLab />

        {/* Key points */}
        <div className="bg-card rounded-2xl p-4 border border-border shadow-sm">
          <h3 className="text-foreground font-black text-sm mb-3">Điểm cần nhớ 📌</h3>
          <div className="flex flex-col gap-2">
            {[
              "Vận tốc không đổi theo thời gian",
              "Quãng đường tỉ lệ thuận với thời gian",
              "Đồ thị s-t là đường thẳng qua gốc tọa độ",
            ].map((point, i) => (
              <div key={i} className="flex items-start gap-2">
                <div className="w-5 h-5 bg-primary/10 rounded-full flex items-center justify-center text-[10px] font-black text-primary shrink-0 mt-0.5">
                  {i + 1}
                </div>
                <p className="text-muted-foreground text-sm">{point}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Bottom CTA */}
      <div className="absolute bottom-0 left-0 right-0 bg-card border-t border-border p-4">
        <button
          onClick={onQuiz}
          className="w-full py-3.5 bg-primary rounded-2xl text-white font-black text-base flex items-center justify-center gap-2 active:scale-95 transition-transform shadow-lg shadow-primary/20"
        >
          Làm bài tập <ChevronRight size={18} />
        </button>
      </div>
    </div>
  );
}
