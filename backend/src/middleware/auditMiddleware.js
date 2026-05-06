import AuditLog from "../models/audit_log.js";

const logAction = async (
  req,
  action,
  entity,
  entityId = null,
  description = null,
  oldData = null,
  newData = null
) => {
  try {
    // Tidak perlu cek req.user
    const userId = req.session.userId || null;

    await AuditLog.create({
      userId: userId,
      action,
      entity,
      entityId,
      description,
      oldData,
      newData,
      ipAddress: req.ip,
      userAgent: req.headers["user-agent"] || "Unknown",
    });
  } catch (error) {
    console.error("Audit log error:", error);
  }
};

// Middleware untuk menambahkan log ke response
const auditMiddleware = (action, entity, options = {}) => {
  return async (req, res, next) => {
    // Simpan data lama untuk operasi update
    let oldData = null;
    if (action === "update" && options.getOldData) {
      oldData = await options.getOldData(req);
    }

    // Override res.json untuk menangkap response
    const originalJson = res.json;
    res.json = async (body) => {
      try {
        // Tentukan entityId
        let entityId = null;
        if (options.entityIdFromResponse) {
          entityId = body[options.entityIdFromResponse];
        } else if (req.params.id) {
          entityId = req.params.id;
        } else if (body.id) {
          entityId = body.id;
        }

        // Log action
        await logAction(
          req,
          action,
          entity,
          entityId,
          options.description,
          oldData,
          action === "update" ? body : null
        );
      } catch (logError) {
        console.error("Error logging action:", logError);
      }
      originalJson.call(res, body);
    };

    next();
  };
};

export { logAction }; 
export default auditMiddleware; 
