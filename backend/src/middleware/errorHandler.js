// Central error handler. Logs full detail server-side but only ever returns a
// generic, safe message to the client — never stack traces, SQL, or provider
// error bodies (which could leak internal infra details).
function notFoundHandler(req, res) {
  res.status(404).json({ error: 'Not found.' });
}

function errorHandler(err, req, res, _next) {
  console.error(`[error] ${req.method} ${req.path}:`, err);

  if (err.type === 'entity.too.large' || err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ error: 'Image is too large. Please use an image under 8MB.' });
  }
  if (err.status === 400 || err.name === 'ValidationError') {
    return res.status(400).json({ error: err.message || 'Invalid request.' });
  }

  res.status(500).json({ error: 'Something went wrong while processing your request. Please try again.' });
}

module.exports = { notFoundHandler, errorHandler };
