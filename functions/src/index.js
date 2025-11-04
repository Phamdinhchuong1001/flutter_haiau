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
