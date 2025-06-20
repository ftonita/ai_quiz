import React, { useEffect, useState } from 'react';

const medals = ['🥇', '🥈', '🥉'];

function ResultsPage() {
  const [leaders, setLeaders] = useState([]);

  const fetchResults = async () => {
    try {
      const response = await fetch('/api/room/leaderboard');
      const data = await response.json();
      setLeaders(data);
    } catch (error) {
      console.error('Error fetching results:', error);
    }
  };

  useEffect(() => {
    // Получаем результаты сразу
    fetchResults();
    
    // Подключаем WebSocket для обновлений
    const ws = new WebSocket('ws://localhost:8000/ws/room');
    
    ws.onopen = () => {
      console.log('WebSocket connected in ResultsPage');
    };
    
    ws.onmessage = (e) => {
      try {
        const data = JSON.parse(e.data);
        // Обновляем результаты при изменении стадии
        if (data.stage === 'results') {
          fetchResults();
        }
      } catch (error) {
        console.error('WebSocket message error:', error);
      }
    };
    
    ws.onerror = (error) => {
      console.error('WebSocket error in ResultsPage:', error);
    };
    
    ws.onclose = () => {
      console.log('WebSocket disconnected in ResultsPage');
    };
    
    return () => ws.close();
  }, []);

  return (
    <div style={{ maxWidth: 480, margin: '40px auto', fontFamily: 'sans-serif' }}>
      <h2 style={{ marginBottom: 24 }}>Результаты</h2>
      {leaders.length === 0 ? (
        <div style={{ textAlign: 'center', fontSize: 18, color: '#888' }}>
          Загрузка результатов...
        </div>
      ) : (
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 18 }}>
          <thead>
            <tr style={{ background: '#f5f5f5' }}>
              <th style={{ textAlign: 'left', padding: 8 }}>#</th>
              <th style={{ textAlign: 'left', padding: 8 }}>Имя</th>
              <th style={{ textAlign: 'right', padding: 8 }}>Баллы</th>
            </tr>
          </thead>
          <tbody>
            {leaders.map((u, i) => (
              <tr key={u.name} style={{ background: i === 0 ? '#fffbe6' : '#fff' }}>
                <td style={{ padding: 8 }}>{medals[i] || i + 1}</td>
                <td style={{ padding: 8 }}>{u.name}</td>
                <td style={{ padding: 8, textAlign: 'right', fontWeight: i === 0 ? 700 : 400 }}>{u.score}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

export default ResultsPage; 