import express from "express";
import { adminOnly, verifyUser } from "../middleware/authUser.js";

import * as userController from "../controllers/userController.js";

const router = express.Router();

// Apply middleware to all routes mapped here (admin endpoints)
router.use(verifyUser, adminOnly);

// Route for getting users by role (with pagination & search)
router.get("/by-role", userController.getUsersByRole);

// Route for viewing user statistics
router.get("/stats", userController.getUserStats);

// Route for managing individual users
router.get("/user/:id", userController.getUserById);
router.post("/user", userController.createUser);
router.patch("/user/:id", userController.updateUser);
router.delete("/user/:id", userController.deleteUser);

export default router;
