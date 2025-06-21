import React, { useEffect, useRef } from 'react';
import './DuckBackground.css';

const DuckBackground = () => {
  const ducksRef = useRef([]);

  useEffect(() => {
    // Функция для анимации уточек при скролле
    const handleScroll = () => {
      const scrollY = window.scrollY;
      const windowHeight = window.innerHeight;
      
      ducksRef.current.forEach((duck, index) => {
        if (duck) {
          const rect = duck.getBoundingClientRect();
          const duckTop = rect.top + scrollY;
          
          // Если уточка в видимой области, добавляем анимацию скролла
          if (duckTop < scrollY + windowHeight && duckTop > scrollY - 100) {
            duck.classList.add('scroll-animate');
          } else {
            duck.classList.remove('scroll-animate');
          }
        }
      });
    };

    // Добавляем обработчик скролла
    window.addEventListener('scroll', handleScroll);
    
    // Вызываем один раз для инициализации
    handleScroll();

    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, []);

  return (
    <div className="duck-background">
      {/* SVG уточки */}
      <svg className="duck-svg" viewBox="0 0 100 100" style={{ display: 'none' }}>
        <defs>
          <linearGradient id="duckGradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style={{ stopColor: '#FFD700', stopOpacity: 1 }} />
            <stop offset="100%" style={{ stopColor: '#FFA500', stopOpacity: 1 }} />
          </linearGradient>
        </defs>
        <g className="duck-body">
          {/* Тело уточки */}
          <ellipse cx="50" cy="60" rx="25" ry="20" fill="url(#duckGradient)" />
          {/* Голова */}
          <circle cx="50" cy="35" r="15" fill="url(#duckGradient)" />
          {/* Клюв */}
          <polygon points="50,30 60,25 50,40" fill="#FF8C00" />
          {/* Глаз */}
          <circle cx="45" cy="32" r="2" fill="#000" />
          {/* Крыло */}
          <ellipse cx="35" cy="55" rx="8" ry="12" fill="url(#duckGradient)" opacity="0.8" />
        </g>
      </svg>
      
      <style jsx>{`
        .duck-background {
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          pointer-events: none;
          z-index: -1;
          overflow: hidden;
        }

        .duck {
          position: absolute;
          width: 40px;
          height: 40px;
          animation: float 6s ease-in-out infinite;
          opacity: 0.6;
        }

        .duck:nth-child(1) {
          top: 10%;
          left: 10%;
          animation-delay: 0s;
          animation-duration: 8s;
        }

        .duck:nth-child(2) {
          top: 20%;
          left: 80%;
          animation-delay: 1s;
          animation-duration: 7s;
        }

        .duck:nth-child(3) {
          top: 60%;
          left: 15%;
          animation-delay: 2s;
          animation-duration: 9s;
        }

        .duck:nth-child(4) {
          top: 70%;
          left: 85%;
          animation-delay: 3s;
          animation-duration: 6s;
        }

        .duck:nth-child(5) {
          top: 40%;
          left: 50%;
          animation-delay: 4s;
          animation-duration: 10s;
        }

        .duck:nth-child(6) {
          top: 80%;
          left: 60%;
          animation-delay: 5s;
          animation-duration: 8s;
        }

        .duck:nth-child(7) {
          top: 30%;
          left: 25%;
          animation-delay: 6s;
          animation-duration: 7s;
        }

        .duck:nth-child(8) {
          top: 50%;
          left: 75%;
          animation-delay: 7s;
          animation-duration: 9s;
        }

        .duck:nth-child(9) {
          top: 15%;
          left: 60%;
          animation-delay: 8s;
          animation-duration: 6s;
        }

        .duck:nth-child(10) {
          top: 85%;
          left: 30%;
          animation-delay: 9s;
          animation-duration: 8s;
        }

        @keyframes float {
          0%, 100% {
            transform: translateY(0px) rotate(0deg) scale(1);
          }
          25% {
            transform: translateY(-20px) rotate(5deg) scale(1.1);
          }
          50% {
            transform: translateY(-10px) rotate(-3deg) scale(0.9);
          }
          75% {
            transform: translateY(-15px) rotate(2deg) scale(1.05);
          }
        }

        .duck:hover {
          animation-play-state: paused;
          transform: scale(1.2);
          transition: transform 0.3s ease;
        }

        /* Анимация для скролла */
        .duck.scroll-animate {
          animation: scrollFloat 2s ease-in-out infinite;
        }

        @keyframes scrollFloat {
          0%, 100% {
            transform: translateY(0px) translateX(0px);
          }
          50% {
            transform: translateY(-30px) translateX(10px);
          }
        }

        /* Медиа-запрос для мобильных устройств */
        @media (max-width: 768px) {
          .duck {
            width: 30px;
            height: 30px;
          }
        }
      `}</style>

      {/* Генерируем уточек */}
      {Array.from({ length: 10 }, (_, i) => (
        <div 
          key={i} 
          className="duck"
          ref={el => ducksRef.current[i] = el}
        >
          <svg viewBox="0 0 100 100" width="100%" height="100%">
            <defs>
              <linearGradient id={`duckGradient${i}`} x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style={{ stopColor: '#FFD700', stopOpacity: 1 }} />
                <stop offset="100%" style={{ stopColor: '#FFA500', stopOpacity: 1 }} />
              </linearGradient>
            </defs>
            <g className="duck-body">
              {/* Тело уточки */}
              <ellipse cx="50" cy="60" rx="25" ry="20" fill={`url(#duckGradient${i})`} />
              {/* Голова */}
              <circle cx="50" cy="35" r="15" fill={`url(#duckGradient${i})`} />
              {/* Клюв */}
              <polygon points="50,30 60,25 50,40" fill="#FF8C00" />
              {/* Глаз */}
              <circle cx="45" cy="32" r="2" fill="#000" />
              {/* Крыло */}
              <ellipse cx="35" cy="55" rx="8" ry="12" fill={`url(#duckGradient${i})`} opacity="0.8" />
            </g>
          </svg>
        </div>
      ))}
    </div>
  );
};

export default DuckBackground; 