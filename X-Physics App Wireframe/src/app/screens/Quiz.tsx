import { useState } from "react";
import { Timer, X, ChevronRight } from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { quizQuestions } from "../data";

interface QuizProps {
  onResult: (score: number, answers: number[]) => void;
  onBack: () => void;
}

export function Quiz({ onResult, onBack }: QuizProps) {
  const [current, setCurrent] = useState(0);
  const [selected, setSelected] = useState<number | null>(null);
  const [answers, setAnswers] = useState<number[]>([]);
  const [showConfirm, setShowConfirm] = useState(false);

  const q = quizQuestions[current];
  const isLast = current === quizQuestions.length - 1;
  const progress = (current + 1) / quizQuestions.length;

  const handleNext = () => {
    if (selected === null) return;
    const newAnswers = [...answers, selected];

    if (isLast) {
      const correct = newAnswers.filter((a, i) => a === quizQuestions[i].correct).length;
      const score = (correct / quizQuestions.length) * 10;
      onResult(score, newAnswers);
    } else {
      setAnswers(newAnswers);
      setCurrent(current + 1);
      setSelected(null);
    }
  };

  const optionLetters = ["A", "B", "C", "D"];

  return (
    <div className="h-full flex flex-col bg-background">
      {/* Header */}
      <div className="bg-card border-b border-border pt-12 pb-3 px-5">
        <div className="flex items-center gap-3 mb-3">
          <button onClick={onBack} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-muted">
            <X size={18} className="text-muted-foreground" />
          </button>
          <div className="flex-1">
            <div className="flex items-center justify-between mb-1">
              <span className="text-foreground font-black text-sm">Câu {current + 1}/{quizQuestions.length}</span>
              <div className="flex items-center gap-1.5 bg-orange-100 rounded-full px-2.5 py-1">
                <Timer size={12} className="text-orange-500" />
                <span className="text-orange-600 text-xs font-black">2:00</span>
              </div>
            </div>
            <div className="h-2 bg-muted rounded-full overflow-hidden">
              <motion.div
                animate={{ width: `${progress * 100}%` }}
                transition={{ duration: 0.4 }}
                className="h-full bg-primary rounded-full"
              />
            </div>
          </div>
        </div>
        <div className="flex gap-1.5">
          {quizQuestions.map((_, i) => (
            <div
              key={i}
              className={`h-1.5 flex-1 rounded-full transition-all ${
                i < current ? "bg-green-400" : i === current ? "bg-primary" : "bg-muted"
              }`}
            />
          ))}
        </div>
      </div>

      {/* Question */}
      <div className="flex-1 overflow-y-auto px-5 pt-5 pb-24 scrollbar-hide">
        <AnimatePresence mode="wait">
          <motion.div
            key={current}
            initial={{ x: 40, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: -40, opacity: 0 }}
            transition={{ duration: 0.25 }}
          >
            <div className="bg-card rounded-2xl p-4 border border-border shadow-sm mb-4">
              <p className="text-foreground font-black text-base leading-relaxed">{q.question}</p>
            </div>

            <div className="flex flex-col gap-3">
              {q.options.map((opt, i) => {
                const isSelected = selected === i;
                return (
                  <motion.button
                    key={i}
                    whileTap={{ scale: 0.97 }}
                    onClick={() => setSelected(i)}
                    className={`w-full p-4 rounded-2xl border-2 text-left transition-all flex items-center gap-3 ${
                      isSelected
                        ? "border-primary bg-primary/5"
                        : "border-border bg-card hover:border-primary/30"
                    }`}
                  >
                    <div
                      className={`w-8 h-8 rounded-xl flex items-center justify-center font-black text-sm shrink-0 transition-all ${
                        isSelected ? "bg-primary text-white" : "bg-muted text-muted-foreground"
                      }`}
                    >
                      {optionLetters[i]}
                    </div>
                    <span className={`font-semibold text-sm flex-1 ${isSelected ? "text-primary" : "text-foreground"}`}>
                      {opt}
                    </span>
                  </motion.button>
                );
              })}
            </div>
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Bottom */}
      <div className="absolute bottom-0 left-0 right-0 bg-card border-t border-border p-4">
        <button
          onClick={isLast ? () => setShowConfirm(true) : handleNext}
          disabled={selected === null}
          className={`w-full py-3.5 rounded-2xl font-black text-base flex items-center justify-center gap-2 transition-all ${
            selected !== null
              ? "bg-primary text-white active:scale-95 shadow-lg shadow-primary/20"
              : "bg-muted text-muted-foreground cursor-not-allowed"
          }`}
        >
          {isLast ? "Nộp bài" : "Câu tiếp theo"}
          <ChevronRight size={18} />
        </button>
      </div>

      {/* Confirm submit */}
      <AnimatePresence>
        {showConfirm && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 bg-black/40 flex items-end justify-center pb-0"
          >
            <motion.div
              initial={{ y: 60 }}
              animate={{ y: 0 }}
              exit={{ y: 60 }}
              className="bg-card rounded-t-3xl p-6 w-full"
            >
              <h3 className="text-foreground font-black text-lg text-center">Nộp bài?</h3>
              <p className="text-muted-foreground text-sm text-center mt-1">
                Bạn đã trả lời {answers.length + (selected !== null ? 1 : 0)}/{quizQuestions.length} câu.
              </p>
              <div className="flex gap-3 mt-5">
                <button
                  onClick={() => setShowConfirm(false)}
                  className="flex-1 py-3.5 bg-muted rounded-2xl font-black text-foreground"
                >
                  Xem lại
                </button>
                <button
                  onClick={handleNext}
                  className="flex-1 py-3.5 bg-primary rounded-2xl font-black text-white shadow-lg shadow-primary/20"
                >
                  Nộp bài ✓
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
