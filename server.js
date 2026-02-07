const express = require('express');
const app = express();
const PORT = 3001;

app.get('/', (req, res) => {
  res.send('GENE1799 Backend Running!');
});

app.listen(PORT, () => {
  console.log('Server running on port ' + PORT);
});

