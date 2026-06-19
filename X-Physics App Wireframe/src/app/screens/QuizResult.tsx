import { motion } from "motion/react";
import { Home, ChevronRight, CheckCircle, XCircle } from "lucide-react";
import { quizQuestions } from "../data";
import { useEffect, useRef } from "react";
import confetti from "canvas-confetti";

interface QuizResultProps {
  score: number;
  answers: number[];
  onHome: () => void;
  onNext: () => void;
}

export function QuizResult({ score, answers, onHome, onNext }: QuizResultProps) {
  const correct = answers.filter((a, i) => a === quizQuestions[i].correct).length;
  const fired = useRef(false);

  useEffect(() => {
    if (!fired.current && score >= 7) {
      fired.current = true;
      confetti({ particleCount: 80, spread: 70, origin: { y: 0.4 } });
    }
  }, [score]);

  const scoreColor = score >= 8 ? "#22C55E" : score >= 5 ? "#F59E0B" : "#EF4444";
  const scoreLabel = score >= 8 ? "Xuất sắc! 🎉" : score >= 5 ? "Tốt lắm! 👍" : "Cố gắng thêm! 💪";

  return (
    <div className="h-full overflow-y-auto bg-background flex flex-col scrollbar-hide">
      {/* Score hero */}
      <div className="bg-gradient-to-b from-primary to-blue-700 pt-12 pb-8 px-5 flex flex-col items-center">
        <motion.div
          initial={{ scale: 0.5, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ type: "spring", duration: 0.6 }}
          className="w-28 h-28 bg-white/10 rounded-full flex items-center justify-center border-4 border-white/20 mb-3"
        >
          <div className="text-center">
            <p className="text-white font-black text-3xl leading-none">{score.toFixed(1)}</p>
            <p className="text-blue-200 text-xs font-medium">/10 điểm</p>
          </div>
        </motion.div>
        <p className="text-white font-black text-lg">{scoreLabel}</p>
        <p className="text-blue-200 text-sm mt-1">Bạn trả lời đúng {correct}/{quizQuestions.length} câu</p>

        {/* Reward */}
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.4 }}
          className="flex gap-3 mt-4"
        >
          <div className="bg-white/10 rounded-2xl px-4 py-2 flex items-center gap-2 border border-white/10">
            <span className="text-lg">🪙</span>
            <div>
              <p className="text-white font-black text-sm">+{correct * 5} xu</p>
              <p className="text-blue-200 text-[10px]">Phần thưởng</p>
            </div>
          </div>
          {score >= 8 && (
            <div className="bg-white/10 rounded-2xl px-4 py-2 flex items-center gap-2 border border-white/10">
              <span className="text-lg">🏅</span>
              <div>
                <p className="text-white font-black text-sm">Huy hiệu mới</p>
                <p className="text-blue-200 text-[10px]">Điểm xuất sắc</p>
              </div>
            </div>
          )}
        </motion.div>
      </div>

      {/* Answer review */}
      <div className="px-5 py-4 flex flex-col gap-3">
        <h3 className="text-foreground font-black text-sm">Xem lại câu trả lời</h3>

        {quizQuestions.map((q, i) => {
          const userAnswer = answers[i];
          const isCorrect = userAnswer === q.correct;
          return (
            <motion.div
              key={i}
              initial={{ x: -20, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: i * 0.07 + 0.3 }}
              className="bg-card rounded-2xl p-4 border border-border shadow-sm"
            >
              <div className="flex items-start gap-2 mb-2">
                {isCorrect ? (
                  <CheckCircle size={16} className="text-green-500 shrink-0 mt-0.5" />
                ) : (
                  <XCircle size={16} className="text-destructive shrink-0 mt-0.5" />
                )}
                <p className="text-foreground font-semibold text-xs leading-relaxed">{q.question}</p>
              </div>
              <div className="flex flex-col gap-1 mt-2">
                <div className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-semibold ${isCorrect ? "bg-green-50 text-green-700" : "bg-red-50 text-red-600"}`}>
                  <span>Bạn chọn:</span>
                  <span className="font-black">{q.options[userAnswer]}</span>
                </div>
                {!isCorrect && (
                  <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-green-50 text-green-700 text-xs font-semibold">
                    <span>Đáp án:</span>
                    <span className="font-black">{q.options[q.correct]}</span>
                  </div>
                )}
              </div>
              <p className="text-muted-foreground text-[11px] mt-2 bg-muted rounded-lg px-3 py-2">
                💡 {q.explanation}
              </p>
            </motion.div>
          );
        })}
      </div>

      {/* Actions */}
      <div className="px-5 pb-8 flex gap-3 mt-2">
        <button
          onClick={onHome}
          className="flex-1 py-3.5 bg-muted rounded-2xl font-black text-foreground flex items-center justify-center gap-2 active:scale-95 transition-transform"
        >
          <Home size={16} /> Trang chủ
        </button>
        <button
          onClick={onNext}
          className="flex-1 py-3.5 bg-primary rounded-2xl font-black text-white flex items-center justify-center gap-2 active:scale-95 transition-transform shadow-lg shadow-primary/20"
        >
          Tiếp theo <ChevronRight size={16} />
        </button>
      </div>
    </div>
  );
}
