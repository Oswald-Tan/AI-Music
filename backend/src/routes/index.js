import express from 'express';
import { body } from 'express-validator';

// Controllers
import { register, login, getProfile } from '../controllers/authController.js';
import { uploadAudio, reuseJobFile } from '../controllers/uploadController.js';
import { processSeparate, processChord, processBeat, processVoice, analyzeSong, processAudio, updateProgress, deleteJob } from '../controllers/processController.js';
import { getResult, getMyJobs, getJobStatus } from '../controllers/resultController.js';
import { createSetlist, getMySetlists, getSetlistDetail, deleteSetlist, addSongToSetlist, removeSongFromSetlist, reorderSetlist } from '../controllers/setlistController.js';

// Middleware
import { authenticateToken } from '../middleware/authMiddleware.js';
import { upload } from '../middleware/uploadMiddleware.js';

const router = express.Router();

// Auth routes
router.post('/auth/register', [
  body('name').notEmpty().withMessage('Name is required'),
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
], register);

router.post('/auth/login', login);
router.get('/auth/profile', authenticateToken, getProfile);

// Upload routes
router.post('/upload', authenticateToken, upload.single('audio'), uploadAudio);
router.post('/jobs/reuse', authenticateToken, reuseJobFile);

// Process routes
router.post('/process/separate', authenticateToken, processSeparate);
router.post('/process/chord', authenticateToken, processChord);
router.post('/process/beat', authenticateToken, processBeat);
router.post('/process/voice', authenticateToken, processVoice);
router.post('/process/analyze', authenticateToken, analyzeSong);
router.post('/process/audio', authenticateToken, processAudio);

// Result & Jobs routes
router.get('/jobs', authenticateToken, getMyJobs);
router.get('/jobs/:id', authenticateToken, getJobStatus);
router.delete('/jobs/:id', authenticateToken, deleteJob);
router.get('/result/:jobId', authenticateToken, getResult);
router.post('/jobs/progress', updateProgress);

// Setlist routes
router.get('/setlists', authenticateToken, getMySetlists);
router.post('/setlists', authenticateToken, createSetlist);
router.post('/setlists/reorder', authenticateToken, reorderSetlist);
router.get('/setlists/:id', authenticateToken, getSetlistDetail);
router.delete('/setlists/:id', authenticateToken, deleteSetlist);
router.post('/setlists/songs', authenticateToken, addSongToSetlist);
router.delete('/setlists/:setlistId/songs/:songId', authenticateToken, removeSongFromSetlist);

export default router;
