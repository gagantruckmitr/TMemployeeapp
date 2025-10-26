@include('Fronted.header')

<style>
  .containerddd {
    display: flex;
    max-width: 1200px;
    margin: 0 auto;
    gap: 40px;
  }
  .left {
    flex: 3;
  }
  .right {
    flex: 1;
    background: #fafafa;
    padding: 20px;
    border: 1px solid #ddd;
    height: fit-content;
  }
  h1 {
    font-size: 28px;
    margin-bottom: 20px;
  }
  h2 {
    font-size: 20px;
    margin-top: 30px;
    margin-bottom: 10px;
    font-weight: 600;
  }
  ul {
    padding-left: 20px;
  }
  li {
    margin-bottom: 10px;
  }
  .apply-btn {
    margin-top: 20px;
    display: inline-block;
    padding: 12px 24px;
    background-color: #111;
    color: #fff;
    text-decoration: none;
    font-weight: 600;
    text-align: center;
  }
  .right h3 {
    margin-top: 20px;
    font-size: 16px;
    font-weight: 600;
  }
  .right p {
    font-size: 15px;
    margin-top: 5px;
  }
  .date-box {
    margin-top: 10px;
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .date-box img {
    width: 16px;
  }
  .contacts {
    margin-top: 40px;
  }
  .contacts p {
    margin-bottom: 6px;
  }

  .modal {
    display: none;
    position: fixed;
    z-index: 10;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    overflow: auto;
    background-color: rgba(0,0,0,0.6);
  }
  .modal-content {
    background-color: #fff;
    margin: 10% auto;
    padding: 20px;
    width: 90%;
    max-width: 500px;
    position: relative;
    border-radius: 8px;
  }
  .close {
    color: #aaa;
    float: right;
    font-size: 24px;
    font-weight: bold;
    position: absolute;
    right: 15px;
    top: 10px;
    cursor: pointer;
  }
</style>

<section class="py-5 contact-bg contact">
  <div class="container py-5">
    <center>
      <div class="row">
        <div class="col-lg-12">
          <h1 class="text-white">Career</h1>
          <ul class="breadcrumb">
            <li><a href="{{ url('/') }}">Home</a></li>
            <li class="text-white">Career Details</li>
          </ul>
        </div>
      </div>
    </center>
  </div>
</section>

<div class="containerddd pt-5">
  <div class="left">
    <h2>Position Title</h2>
    <h1>{{ $career->position_title }}</h1>

    <h2>Description</h2>
    <p>{!! nl2br(e($career->description)) !!}</p>

    <h2>Key Responsibilities</h2>
    <ul>
      @foreach(explode("\n", $career->key_responsibilities) as $item)
        <li>{{ $item }}</li>
      @endforeach
    </ul>

    <h2>Qualification</h2>
    <ul>
      @foreach(explode("\n", $career->qualification) as $item)
        <li>{{ $item }}</li>
      @endforeach
    </ul>

    <div class="contacts">
      <h2>Contacts</h2>
      <p>{{ $career->contact_address ?? 'Not provided' }}</p>
      @if($career->contact_email)
        <p><a href="mailto:{{ $career->contact_email }}">{{ $career->contact_email }}</a></p>
      @endif
      @if($career->contact_phone)
        <p>{{ $career->contact_phone }}</p>
      @endif
    </div>
  </div>

  <div class="right">
    <h3>Hiring Organization</h3>
    <p>{{ $career->hiring_organization }}</p>

    <h3>Position</h3>
    <p>{{ $career->position_title }}</p>

    <h3>Job Location</h3>
    <p>{{ $career->job_location }}</p>

    <h3>Date Posted</h3>
    <div class="date-box">
      <img src="https://img.icons8.com/ios-filled/50/000000/calendar.png" alt="calendar"/>
      <p>{{ \Carbon\Carbon::parse($career->date_posted)->format('d M Y') }}</p>
    </div>

    <a href="#" class="apply-btn" id="openModal">APPLY NOW</a>
  </div>
</div>

<!-- Modal Popup -->
<!-- Modal Popup -->
<div id="applyModal" class="modal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background-color:rgba(0,0,0,0.5); z-index:999;">
  <div class="modal-content" style="background:#fff; padding:20px; margin:10% auto; width:50%; position:relative;">
    <span class="close" id="closeModal" style="position:absolute; top:10px; right:20px; font-size:24px; cursor:pointer;">&times;</span>
    
    <h2>Apply for {{ $career->position_title ?? 'Job' }}</h2>

    {{-- Alert Messages --}}
    @if(session('success'))
        <div class="alert alert-success" style="color:green; margin-bottom:10px;">
            {{ session('success') }}
        </div>
    @endif

    @if($errors->any())
        <div class="alert alert-danger" style="color:red; margin-bottom:10px;">
            <ul>
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <form action="{{ route('career.apply') }}" method="POST" enctype="multipart/form-data">
        @csrf
        <label for="name">Full Name:</label><br/>
        <input type="text" id="name" name="name" required style="width:100%; padding:8px;"><br/><br/>

        <label for="email">Email:</label><br/>
        <input type="email" id="email" name="email" required style="width:100%; padding:8px;"><br/><br/>

        <label for="phone">Phone Number:</label><br/>
    <input type="text" id="phone" name="phone" pattern="^[6-9][0-9]{9}$" title="Phone number must be exactly 10 digits" style="width:100%; padding:8px;" maxlength="10" required/><br/><br/>

        <label for="resume">Upload Resume (PDF, DOC, DOCX):</label><br/>
        <input type="file" id="resume" name="resume" required><br/><br/>

        <button type="submit" style="padding:10px 20px; background-color:#222; color:#fff; border:none; cursor:pointer;">Submit Application</button>
    </form>
  </div>
</div>

<script>
    // Show modal if there is success or error message
    document.addEventListener('DOMContentLoaded', function () {
        @if(session('success') || $errors->any())
            document.getElementById('applyModal').style.display = 'block';
        @endif

        // Close modal
        document.getElementById('closeModal').onclick = function () {
            document.getElementById('applyModal').style.display = 'none';
        };
    });
</script>


<script>
  const modal = document.getElementById("applyModal");
  const openBtn = document.getElementById("openModal");
  const closeBtn = document.getElementById("closeModal");

  openBtn.onclick = () => modal.style.display = "block";
  closeBtn.onclick = () => modal.style.display = "none";
  window.onclick = (e) => {
    if (e.target == modal) modal.style.display = "none";
  };
</script>

@include('Fronted.footer')
