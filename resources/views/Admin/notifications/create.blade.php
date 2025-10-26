@include('Admin.layouts.header')

<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <h3 class="page-title">Send Notification</h3>
        </div>

        @if(session('success'))
            <div class="alert alert-success">{{ session('success') }}</div>
        @endif

        @if($errors->any())
            <div class="alert alert-danger">
                <ul>
                    @foreach($errors->all() as $err)
                        <li>{{ $err }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('admin.notifications.store') }}" method="POST" enctype="multipart/form-data">
            @csrf

            <div class="form-group">
                <label>Title <span class="text-danger">*</span></label>
                <input type="text" name="title" class="form-control" required>
            </div>

            <div class="form-group">
                <label>Message <span class="text-danger">*</span></label>
                <textarea name="message" class="form-control" rows="4" required></textarea>
            </div>

            <div class="form-group">
                <label>Send To <span class="text-danger">*</span></label>
                <select name="send_to" id="send_to" class="form-control" required>
                    <option value="">-- Select Audience --</option>
                    <option value="all_drivers">All Drivers</option>
                    <option value="all_transporters">All Transporters</option>
                    <option value="all_users">All Users (Drivers + Transporters)</option>
                    <option value="authenticated_user">Authenticated User</option>
                    <option value="selected_numbers">Selected Mobile Numbers</option>
                    <option value="unauthorized_users">Unauthorized (Unregistered) Users</option>
                </select>
            </div>

            <div class="form-group" id="mobile_numbers_group" style="display:none;">
                <label>Mobile Numbers (comma separated):</label>
                <input type="text" name="mobile" class="form-control" placeholder="9999999999,8888888888">
                <small class="text-muted">Enter one or more mobile numbers separated by commas.</small>
            </div>

            <div class="form-group">
                <label>Notification Banner Image (Optional):</label>
                <input type="file" name="image" id="imageInput" class="form-control" accept="image/*">
                <small class="text-muted">Image will show on the right side of the notification.</small>
                <div id="imagePreview" class="mt-2">
                    <img id="previewImg" src="#" alt="Preview" style="max-width: 300px; display: none;" />
                </div>
            </div>

            <button type="submit" class="btn btn-primary">Send Notification</button>
        </form>
    </div>
</div>

<script>
    const sendToSelect = document.getElementById('send_to');
    const mobileGroup = document.getElementById('mobile_numbers_group');

    sendToSelect.addEventListener('change', function() {
        const selected = this.value;
        const mobileInput = mobileGroup.querySelector('input');
        if (selected === 'selected_numbers') {
            mobileGroup.style.display = 'block';
            mobileInput.setAttribute('required', 'required');
        } else {
            mobileGroup.style.display = 'none';
            mobileInput.removeAttribute('required');
        }
    });

    window.addEventListener('DOMContentLoaded', () => {
        sendToSelect.dispatchEvent(new Event('change'));
    });

    document.getElementById('imageInput').addEventListener('change', function(event) {
        const reader = new FileReader();
        const file = event.target.files[0];
        const previewImg = document.getElementById('previewImg');

        if (file) {
            reader.onload = function(e) {
                previewImg.src = e.target.result;
                previewImg.style.display = 'block';
            };
            reader.readAsDataURL(file);
        } else {
            previewImg.src = '#';
            previewImg.style.display = 'none';
        }
    });
</script>

@include('Admin.layouts.footer')
