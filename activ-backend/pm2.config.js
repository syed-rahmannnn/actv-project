module.exports = {
    apps: [{
        name: 'activ-backend',
        script: 'server.js',
        instances: 'max',
        exec_mode: 'cluster',
        watch: false,
        max_memory_restart: '500M',
        env: {
            NODE_ENV: 'production',
            PORT: 3000
        },
        env_development: {
            NODE_ENV: 'development',
            PORT: 3000
        },
        error_file: 'logs/error.log',
        out_file: 'logs/out.log',
        log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
        merge_logs: true,
        autorestart: true,
        max_restarts: 10,
        min_uptime: '10s',
        listen_timeout: 3000,
        kill_timeout: 5000
    }]
};