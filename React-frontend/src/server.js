// server.js
const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

// Endpoint to receive recommendations from the backend
app.post('/updateRecommendations', (req, res) => {
    const recommendations = req.body;
    console.log('Received recommendations:', recommendations);
    // Handle the recommendations (e.g., update the UI or notify the user)
    res.sendStatus(200);
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
    console.log(`Frontend service listening on port ${port}`);
});
