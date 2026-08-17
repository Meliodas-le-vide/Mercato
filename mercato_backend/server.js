const express = require('express');
const sequelize = require('./config/database');
const authRoutes = require('./src/routes/authRoutes');

const app = express();
app.use(express.json());
app.use('/api/auth', authRoutes);

sequelize
.sync()
.then(()=> {
    console.log('Database synced');
    app.listen( process.env.PORT, ()=> {
        console.log(`server running on port ${process.env.PORT}`);
    })
}).catch(console.error);