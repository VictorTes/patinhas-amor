import { motion } from "framer-motion";

interface Props {
  children: React.ReactNode;
  delay?: number;
  direction?: "up" | "down" | "left" | "right";
}

export function FadeIn({ children, delay = 0, direction }: Props) {
  return (
    <motion.div
      initial={{ 
        opacity: 0, 
        y: direction === "up" ? 20 : direction === "down" ? -20 : 0,
        x: direction === "left" ? 20 : direction === "right" ? -20 : 0
      }}
      whileInView={{ opacity: 1, y: 0, x: 0 }}
      viewport={{ once: true }} // Anima apenas uma vez ao scrolar
      transition={{ 
        duration: 0.6, 
        delay: delay, 
        ease: "easeOut" 
      }}
    >
      {children}
    </motion.div>
  );
}