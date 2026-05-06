// middleware/transactionValidation.js
export const validateTransactionStatus = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const userId = req.userId;
    
    const transaction = await Transaction.findOne({
      where: { id: orderId, user_id: userId }
    });
    
    if (!transaction) {
      return res.status(404).json({
        success: false,
        message: "Transaction not found"
      });
    }
    
    // Jika transaction sudah CANCELED/EXPIRED, tolak force sync
    if (['CANCELED', 'EXPIRED', 'DENIED'].includes(transaction.status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot sync - transaction is ${transaction.status}`,
        code: 'TRANSACTION_INVALID'
      });
    }
    
    // Simpan transaction di request untuk digunakan di controller
    req.transaction = transaction;
    next();
  } catch (error) {
    console.error("Transaction validation error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};
