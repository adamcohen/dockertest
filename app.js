const express = require('express')
const app = express()
const port = 3000

app.get('/', (req, res) => {
  res.json({
    text: 'Hello World!',
    sha: process.env.CURRENT_SHA || 'SHA not available'
  })
})

app.get('/status', (req, res) => {
  res.status(200).send('ok');
});

app.listen(port, () => console.log(`Example app listening on port ${port}!`))
