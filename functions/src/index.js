const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp(); 
const db = admin.firestore();
const SAMPLES_COLLECTION = 'samples'; 
const COUNTER_DOC = 'counters/sample'; 

const checkRole = (context, requiredRole) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Yêu cầu đăng nhập.');
    }
    
    const userRole = context.auth.token.role || 'nhanvien'; 
    
    if (userRole !== requiredRole) {
        throw new functions.https.HttpsError(
            'permission-denied', 
            `Bạn không có quyền '${requiredRole}' để thực hiện thao tác này.`
        );
    }
    return userRole;
};

exports.getNewSampleCode = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Yêu cầu đăng nhập.');
    }

    try {
        const counterRef = db.doc(COUNTER_DOC);
        const counterDoc = await counterRef.get();

        if (!counterDoc.exists) {
            throw new functions.https.HttpsError('failed-precondition', 'Lỗi cấu hình: Tài liệu Counter không tồn tại. Vui lòng tạo counters/sample.');
        }

        const currentSequence = counterDoc.data().sequence || 0;
        const nextSequence = currentSequence + 1;
        
        const year = new Date().getFullYear();
        const paddedSequence = String(nextSequence).padStart(5, '0');
        const newSampleCode = `HA-${year}-${paddedSequence}`;
        
        return { sampleCode: newSampleCode, nextSequence: nextSequence };

    } catch (error) {
        console.error("Lỗi khi tạo Mã mẫu:", error);
        if (error.code === 'failed-precondition') {
             throw error;
        }
        throw new functions.https.HttpsError('internal', `Lỗi server khi tạo mã: ${error.message}`);
    }
});

exports.addSample = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Yêu cầu đăng nhập.');
    }
    
    const { sampleCode, customerName, sampleType, receivedDate, status, nextSequence } = data; 

    if (!sampleCode) throw new functions.https.HttpsError('invalid-argument', 'Thiếu thông tin bắt buộc: Mã mẫu.'); 
    if (!customerName) throw new functions.https.HttpsError('invalid-argument', 'Thiếu thông tin bắt buộc: Tên khách hàng.');
    if (!sampleType) throw new functions.https.HttpsError('invalid-argument', 'Thiếu thông tin bắt buộc: Loại mẫu.');
    if (!receivedDate) throw new functions.https.HttpsError('invalid-argument', 'Thiếu thông tin bắt buộc: Ngày nhận.');
    if (!status) throw new functions.https.HttpsError('invalid-argument', 'Thiếu thông tin bắt buộc: Trạng thái.');
    if (!nextSequence || typeof nextSequence !== 'number') throw new functions.https.HttpsError('internal', 'Lỗi dữ liệu: Thiếu số thứ tự (nextSequence) để cập nhật counter.');


    try {
        await db.runTransaction(async (transaction) => {
            const counterRef = db.doc(COUNTER_DOC);
            
            transaction.update(counterRef, { sequence: nextSequence }); // <--- CẬP NHẬT COUNTER
            
            const newSample = {
                sampleCode: sampleCode.trim(),
                customerName: customerName.trim(),
                sampleType: sampleType.trim(),
                receivedDate: receivedDate.trim(),
                status: status.trim(), 
                createdAt: admin.firestore.Timestamp.now(),
                updatedAt: admin.firestore.Timestamp.now(),
                createdBy: context.auth.uid, 
            };

            const docRef = db.collection(SAMPLES_COLLECTION).doc();
            transaction.set(docRef, newSample);
        });

        return { success: true, message: 'Thêm mẫu thành công!', sampleCode: sampleCode };
        
    } catch (error) {
        console.error("Lỗi khi thêm mẫu:", error);
        throw new functions.https.HttpsError('internal', `Lỗi server khi tạo mẫu: ${error.message}`);
    }
});

exports.updateSampleStatus = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Yêu cầu đăng nhập.');
    }
    
    const { id, status } = data;
    if (!id || !status) {
        throw new functions.https.HttpsError('invalid-argument', 'Thiếu ID mẫu hoặc trạng thái mới.');
    }

    try {
        const sampleRef = db.collection(SAMPLES_COLLECTION).doc(id);
        
        const doc = await sampleRef.get();
        if (!doc.exists) {
            throw new functions.https.HttpsError('not-found', 'Tài liệu mẫu cần cập nhật không tồn tại.');
        }

        await sampleRef.update({
            status: status.trim(),
            updatedAt: admin.firestore.Timestamp.now(),
        });

        return { success: true, message: `Cập nhật trạng thái thành công!` };
    } catch (error) {
        console.error("Lỗi khi cập nhật trạng thái mẫu:", error);
        if (error.code === 'not-found') {
             throw error; 
        }
        throw new functions.https.HttpsError('internal', `Lỗi server khi cập nhật: ${error.message}`);
    }
});

exports.deleteSample = functions.https.onCall(async (data, context) => {
    checkRole(context, 'admin'); 

    const { id } = data;
    if (!id) {
        throw new functions.https.HttpsError('invalid-argument', 'Thiếu ID mẫu cần xóa.');
    }

    try {
        const sampleRef = db.collection(SAMPLES_COLLECTION).doc(id);
        
        const doc = await sampleRef.get();
        if (!doc.exists) {
            throw new functions.https.HttpsError('not-found', 'Tài liệu mẫu cần xóa không tồn tại.');
        }

        await sampleRef.delete();

        return { success: true, message: `Xóa mẫu ${id} thành công!` };
    } catch (error) {
        console.error("Lỗi khi xóa mẫu:", error);
        if (error.code === 'not-found' || error.code === 'permission-denied') {
             throw error; 
        }
        throw new functions.https.HttpsError('internal', `Lỗi server khi xóa: ${error.message}`);
    }
});
// ======================================================
// =================== USER MANAGEMENT ===================
// ======================================================

const USERS_COLLECTION = 'users';
const ADMIN_EMAIL = 'haiau@admin.com';
const ADMIN_PASSWORD = '123456';

// ✅ Function check quyền admin
async function isAdmin(uid) {
  const user = await admin.auth().getUser(uid);
  return user.customClaims && user.customClaims.role === 'admin';
}

// ✅ Function đảm bảo luôn có 1 admin cố định tồn tại
async function ensureAdminAccount() {
  try {
    // Kiểm tra xem admin cố định đã tồn tại chưa
    const user = await admin.auth().getUserByEmail(ADMIN_EMAIL);
    console.log('✅ Admin đã tồn tại:', user.email);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      // Nếu chưa có thì tạo mới
      const adminUser = await admin.auth().createUser({
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
        displayName: 'Admin cố định',
      });

      await admin.auth().setCustomUserClaims(adminUser.uid, { role: 'admin' });
      await db.collection(USERS_COLLECTION).doc(adminUser.uid).set({
        uid: adminUser.uid,
        fullname: 'Admin cố định',
        email: ADMIN_EMAIL,
        role: 'admin',
        createdAt: admin.firestore.Timestamp.now(),
      });

      console.log('✅ Đã tạo admin cố định:', ADMIN_EMAIL);
    } else {
      console.error('❌ Lỗi khi kiểm tra admin:', error);
    }
  }
}

// ✅ Gọi hàm khi khởi chạy (tự đảm bảo admin luôn tồn tại)
ensureAdminAccount();

// ✅ API thủ công để tạo lại admin nếu bị xóa
exports.reinitAdmin = functions.https.onRequest(async (req, res) => {
  try {
    await ensureAdminAccount();
    res.status(200).send('✅ Đã kiểm tra và tạo lại admin nếu bị xóa.');
  } catch (error) {
    console.error('❌ Lỗi khi chạy reinitAdmin:', error);
    res.status(500).send('❌ Lỗi khi chạy reinitAdmin.');
  }
});
//https://us-central1-haiau-lab-manager.cloudfunctions.net/reinitAdmin

// ✅ 1. ĐĂNG KÝ USER (chỉ được tạo tài khoản nhân viên)
exports.registerUser = functions.https.onCall(async (data, context) => {
  const { fullname, email, password } = data;
  if (!fullname || !email || !password ) {
    throw new functions.https.HttpsError('invalid-argument', 'Thiếu thông tin đăng ký.');
  }

  // 🚫 Không cho phép tạo email admin
  if (email.trim().endsWith('@admin.com')) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Không thể tạo tài khoản admin.'
    );
  }

  try {
    const userRecord = await admin.auth().createUser({
      email: email.trim(),
      password: password.trim(),
      displayName: fullname.trim(),
    });

    // Luôn set role = staff
    const role = 'staff';
    await admin.auth().setCustomUserClaims(userRecord.uid, { role });

    await db.collection(USERS_COLLECTION).doc(userRecord.uid).set({
      uid: userRecord.uid,
      fullname,
      email,
      role,
      createdAt: admin.firestore.Timestamp.now(),
    });

    return { success: true, message: 'Đăng ký thành công!', role };
  } catch (error) {
    console.error('Lỗi khi tạo user:', error);
    throw new functions.https.HttpsError('internal', 'Không tạo được tài khoản.');
  }
});

// ✅ 2. LẤY DANH SÁCH USER (admin + staff đều xem được)
exports.getUsers = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError('unauthenticated', 'Bạn chưa đăng nhập.');

  const snapshot = await db.collection(USERS_COLLECTION).get();
  const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  return { success: true, users };
});

// ✅ 3. UPDATE USER (chỉ admin)
exports.updateUser = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError('unauthenticated', 'Bạn chưa đăng nhập.');
  const adminCheck = await isAdmin(context.auth.uid);
  if (!adminCheck)
    throw new functions.https.HttpsError('permission-denied', 'Bạn không phải admin.');

  const { uid, fullname, role } = data;
  if (!uid)
    throw new functions.https.HttpsError('invalid-argument', 'Thiếu UID.');

  await db.collection(USERS_COLLECTION).doc(uid).update({
    fullname,
    role,
    updatedAt: admin.firestore.Timestamp.now(),
  });

  if (role) await admin.auth().setCustomUserClaims(uid, { role });
  return { success: true, message: 'Cập nhật thành công!' };
});

// ✅ 4. DELETE USER (chỉ admin, không được xóa admin)
exports.deleteUser = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError('unauthenticated', 'Bạn chưa đăng nhập.');
  const adminCheck = await isAdmin(context.auth.uid);
  if (!adminCheck)
    throw new functions.https.HttpsError('permission-denied', 'Bạn không phải admin.');

  const { uid } = data;
  if (!uid)
    throw new functions.https.HttpsError('invalid-argument', 'Thiếu UID.');

  try {
    const user = await admin.auth().getUser(uid);

    // 🚫 Không cho xóa admin cố định hoặc bất kỳ admin nào
    if (user.email === ADMIN_EMAIL || (user.customClaims && user.customClaims.role === 'admin')) {
      throw new functions.https.HttpsError('permission-denied', 'Không thể xóa tài khoản admin.');
    }

    await admin.auth().deleteUser(uid);
    await db.collection(USERS_COLLECTION).doc(uid).delete();

    return { success: true, message: 'Xóa tài khoản nhân viên thành công!' };
  } catch (error) {
    console.error('Lỗi khi xóa user:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
