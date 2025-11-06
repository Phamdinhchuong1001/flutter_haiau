const functions = require('firebase-functions');
const admin = require('firebase-admin');

try { admin.initializeApp(); } catch(e) { console.error('Firebase Admin Init failed:', e); }

const db = admin.firestore();
const SAMPLES_COLLECTION = 'samples';

exports.addSample = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'Chỉ nhân viên đã đăng nhập mới được thêm mẫu.'
        );
    }
    
    const { sampleCode, customerName, sampleType, receivedDate, status } = data;

    if (!sampleCode || !customerName || !sampleType || !receivedDate || !status) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Thiếu thông tin bắt buộc'
        );
    }

    try {
        const newSample = {
            sampleCode: sampleCode.trim(),
            customerName: customerName.trim(),
            sampleType: sampleType.trim(),
            receivedDate: receivedDate.trim(),
            status: status.trim(), 
            createdAt: admin.firestore.Timestamp.now(),
            updatedAt: admin.firestore.Timestamp.now(),
        };

        const docRef = await db.collection(SAMPLES_COLLECTION).add(newSample);

        return {
            success: true,
            message: 'Thêm mẫu thành công!',
            id: docRef.id,
        };
    } catch (error) {
        console.error("Lỗi khi thêm mẫu:", error);
        throw new functions.https.HttpsError(
            'internal',
            'Lỗi server khi tạo mẫu.'
        );
    }
});

exports.updateSampleStatus = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'Chỉ nhân viên đã đăng nhập mới được cập nhật trạng thái.'
        );
    }
    
    const { id, status } = data;

    if (!id || !status) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Thiếu ID mẫu hoặc trạng thái mới.'
        );
    }

    try {
        const sampleRef = db.collection(SAMPLES_COLLECTION).doc(id);
        
        await sampleRef.update({
            status: status.trim(),
            updatedAt: admin.firestore.Timestamp.now(),
        });

        return {
            success: true,
            message: `Cập nhật trạng thái mẫu ${id} thành công thành: ${status}`,
        };
    } catch (error) {
        console.error("Lỗi khi cập nhật trạng thái mẫu:", error);
        throw new functions.https.HttpsError(
            'internal',
            'Lỗi server khi cập nhật trạng thái. (Có thể ID mẫu không tồn tại)'
        );
    }
});

exports.deleteSample = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'Chỉ nhân viên đã đăng nhập mới được xóa mẫu.'
        );
    }
    
    const { id } = data;

    if (!id) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Thiếu ID mẫu cần xóa.'
        );
    }

    try {
        await db.collection(SAMPLES_COLLECTION).doc(id).delete();

        return {
            success: true,
            message: `Xóa mẫu ${id} thành công!`,
        };
    } catch (error) {
        console.error("Lỗi khi xóa mẫu:", error);
        throw new functions.https.HttpsError(
            'internal',
            'Lỗi server khi xóa mẫu.'
        );
    }
});
// ======================================================
// =================== USER MANAGEMENT ===================
// ======================================================

const USERS_COLLECTION = 'users';

// ✅ Function check quyền admin
async function isAdmin(uid) {
  const user = await admin.auth().getUser(uid);
  return user.customClaims && user.customClaims.role === 'admin';
}

// ✅ 1. ĐĂNG KÝ USER (ai cũng gọi được)
exports.registerUser = functions.https.onCall(async (data, context) => {
  const { fullname, birthDate, email, password, position } = data;
  if (!fullname || !birthDate || !email || !password || !position) {
    throw new functions.https.HttpsError('invalid-argument', 'Thiếu thông tin đăng ký.');
  }

  try {
    const userRecord = await admin.auth().createUser({
      email: email.trim(),
      password: password.trim(),
      displayName: fullname.trim(),
    });

    const role = email.endsWith('@admin.com') ? 'admin' : 'staff';
    await admin.auth().setCustomUserClaims(userRecord.uid, { role });

    await db.collection(USERS_COLLECTION).doc(userRecord.uid).set({
      uid: userRecord.uid,
      fullname,
      birthDate,
      email,
      position,
      role,
      createdAt: admin.firestore.Timestamp.now(),
    });

    return { success: true, message: 'Đăng ký thành công!', role };
  } catch (error) {
    throw new functions.https.HttpsError('internal', 'Không tạo được tài khoản.');
  }
});

// ✅ 2. LẤY DANH SÁCH USER (admin + staff đều xem được)
exports.getUsers = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Bạn chưa đăng nhập.');

  const snapshot = await db.collection(USERS_COLLECTION).get();
  const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  return { success: true, users };
});

// ✅ 3. UPDATE USER (chỉ admin)
exports.updateUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Bạn chưa đăng nhập.');
  const adminCheck = await isAdmin(context.auth.uid);
  if (!adminCheck) throw new functions.https.HttpsError('permission-denied', 'Bạn không phải admin.');

  const { uid, fullname, birthDate, position, role } = data;
  if (!uid) throw new functions.https.HttpsError('invalid-argument', 'Thiếu UID.');

  await db.collection(USERS_COLLECTION).doc(uid).update({
    fullname,
    birthDate,
    position,
    role,
    updatedAt: admin.firestore.Timestamp.now(),
  });

  if (role) await admin.auth().setCustomUserClaims(uid, { role });
  return { success: true, message: 'Cập nhật thành công!' };
});

// ✅ 4. DELETE USER (chỉ admin)
exports.deleteUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Bạn chưa đăng nhập.');
  const adminCheck = await isAdmin(context.auth.uid);
  if (!adminCheck) throw new functions.https.HttpsError('permission-denied', 'Bạn không phải admin.');

  const { uid } = data;
  if (!uid) throw new functions.https.HttpsError('invalid-argument', 'Thiếu UID.');

  await db.collection(USERS_COLLECTION).doc(uid).delete();
  await admin.auth().deleteUser(uid);

  return { success: true, message: 'Xoá tài khoản thành công!' };
  });
