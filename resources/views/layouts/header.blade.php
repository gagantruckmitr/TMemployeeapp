<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=0">
    <title>Drivers Dashboard</title>
    <link rel="shortcut icon" href="{{url('public/front/assets/images/logotrick.png')}}">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,400;0,500;0,700;0,900;1,400;1,500;1,700&display=swap"rel="stylesheet">
    <link rel="stylesheet" href="{{url('public/assets/plugins/bootstrap/css/bootstrap.min.css')}}">
    <link rel="stylesheet" href="{{url('public/assets/plugins/feather/feather.css')}}">
    <link rel="stylesheet" href="{{url('public/assets/plugins/icons/flags/flags.css')}}">
    <link rel="stylesheet" href="{{url('public/assets/plugins/fontawesome/css/fontawesome.min.css')}}">
    <link rel="stylesheet" href="{{url('public/assets/plugins/fontawesome/css/all.min.css')}}">
    <link rel="stylesheet" href="{{url('public/assets/css/style.css')}}">
    <link rel="icon" type="image/x-icon" href="{{url('public/front/assets/images/logotrick.png')}}">
     <script type="text/javascript" src="https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit"></script>

</head>

<body>

    <div class="main-wrapper">

        <div class="header">

            <div class="header-left">
                <a href="" class="logo">
                    <img src="{{url('public/assets/img/logo.png')}}" alt="Logo">
                </a>
                <a href="" class="logo logo-small">
                    <img src="{{url('public/assets/img/logo.png')}}" alt="Logo" width="30" height="30">
                </a>
                
               

            </div>
            <div class="menu-toggle">
                <a href="javascript:void(0);" id="toggle_btn">
                    <i class="fas fa-bars"></i>
                </a>
            </div>

           
            <a class="mobile_btn" id="mobile_btn">
                <i class="fas fa-bars"></i>
            </a>

            <ul class="nav user-menu">
               
                <li class="nav-item zoom-screen me-2">
                    <a href="#" class="nav-link header-nav-list win-maximize">
                        <img src="{{url('public/assets/img/icons/header-icon-04.svg')}}" alt="">
                    </a>
                </li>

                <li class="nav-item dropdown has-arrow new-user-menus">
                    <a href="#" class="dropdown-toggle nav-link" data-bs-toggle="dropdown">
                       <span class="user-img">  
                                @php
                                    $id = Session::get('id');
                                    $user = null;
                            
                                    if ($id) {
                                        $user = \App\Models\User::where('id', $id)->where('role', 'driver')->first();
                                    }
                                @endphp
                            
                                @if ($user)  
                                    <img class="rounded-circle" src="{{ url('public/' . $user->images) }}" width="31" alt="Image">
                                @else
                                    <img class="rounded-circle" src="{{ url('public/default-user.png') }}" width="31" alt="Default Image">
                                @endif
                            
                                <div class="user-text">
                                    <h6 style="margin-top:10px;">
                                        @if (Session::has('name') || Session::has('role'))
                                            {{ Session::get('name') }}
                                        @endif
                                    </h6>
                                    <p class="text-muted mb-0">
                                        @if (Session::has('role'))
                                            {{ Session::get('role') }}
                                        @endif
                                    </p>
                                </div>
                            </span>

                    </a>
                    <div class="dropdown-menu">
                       <a class="dropdown-item" href="{{url('logouts')}}">Logout</a>
                    </div>
                </li>

            </ul>

        </div>


        <div class="sidebar" id="sidebar">
            <div class="sidebar-inner slimscroll">
                <div id="sidebar-menu" class="sidebar-menu">
                    <ul>
                        <li class="menu-title">
                            <span>Main Menu</span>
                        </li>
                        <li class="submenu">
                            <a href="#"><i class="feather-grid"></i> <span> Dashboard</span> <span
                                    class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('driver/dashboard')}}" class="{{ request()->is('driver/dashboard') ? 'active' : '' }}">Dashboard</a></li>
                                
                            </ul>
                        </li>
                        <li class="submenu">
                            <a href="#"><i class="fas fa-user"></i> <span> My Profile</span> <span
                                    class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('driver/profile')}}" class="{{ request()->is('driver/profile') ? 'active' : '' }}">Profile</a></li>
                               
                            </ul>
                        </li>
                        @php
                            use Illuminate\Support\Facades\Session;
                        
                            $id = Session::get('id');
                            
                            $user = null;
                            if ($id) {
                                $user = \App\Models\User::where('id', $id)->where('role', 'driver')->first();
                            }
                            @endphp
                            @if ($user && empty($user->vehicle_type))
                                  <script>
                                    window.addEventListener("load", (event) => {
                                      // Create the modal structure dynamically
                                      const modalHTML = `
                                        <div class="modal" tabindex="-1" role="dialog">
                                          <div class="modal-dialog" role="document">
                                            <div class="modal-content">
                                              <div class="modal-body">
                                              <h5 style="color:blue;text-align: center;">Welcome To Truckmitr</h5>
                                                <p>Please update your profile to access the dashboard features.</p>
                                              </div>
                                              <div class="modal-footer">
                                                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                                              </div>
                                            </div>
                                          </div>
                                        </div>
                                      `;
                                    
                                      // Append the modal HTML to the body
                                      document.body.insertAdjacentHTML('beforeend', modalHTML);
                                    
                                      // Show the modal using Bootstrap's modal method
                                      const modal = document.querySelector('.modal');
                                      $(modal).modal('show');
                                    
                                      // Handle the closing of the modal manually
                                      const closeButton = modal.querySelector('.btn-secondary');
                                      closeButton.addEventListener('click', () => {
                                        $(modal).modal('hide'); // Manually hide the modal when the "Close" button is clicked
                                      });
                                    });
                            </script>
                            	<li class="submenu">
                                       <a href="#"><i class="fas fa-video-camera"></i> <span> Video</span> <span class="menu-arrow"></span></a>
                                </li>
                            <li class="submenu">
                                <a href="#"><i class="fas fa-graduation-cap"></i> <span> Jobs</span> <span class="menu-arrow"></span></a>
                            </li>
                        
                             @elseif ($user && !empty($user->Aadhar_Number))
                             <li class="submenu">
                                <a href="#"><i class="fas fa-video"></i> <span>My Training</span> <span
                                        class="menu-arrow"></span></a>
                                <ul>
                                    <li><a href="{{url('driver/videos')}}" class="{{ request()->is('driver/videos') ? 'active' : '' }}">Video Training</a></li>
                                    <!--<li><a href="{{url('driver/videos')}}">Quizzes</a></li>-->
                                    <li><a href="{{url('driver/quizcount')}}" class="{{ request()->is('driver/quizcount') ? 'active' : '' }}">Quiz Result</a></li>
                                    <li><a href="{{url('driver/health-hygiene')}}" class="{{ request()->is('driver/health-hygiene') ? 'active' : '' }}">Health & Hygiene</a></li>
                                   
                                </ul>
                            </li>
                             
                           
    						
                           
    
    						<li class="submenu">
                                <a href="#"><i class="fas fa-briefcase"></i> <span> Jobs</span> <span
                                        class="menu-arrow"></span></a>
                                <ul>
                                    <li><a href="{{url('driver/jobs-all')}}" class="{{ request()->is('driver/jobs-all') ? 'active' : '' }}">Available Jobs</a></li>
                                    <li><a href="{{url('driver/applied-jobs')}}" class="{{ request()->is('driver/applied-jobs') ? 'active' : '' }}">Applied Jobs</a></li>
                                   
                                </ul>
                            </li>
						 @endif
					     
							<li>
                            <a href="{{url('logouts')}}"><i class="fas fa-sign-out-alt"></i> <span>Logout</span></a>
                        </li>
                        
                        <li><div id="google_translate_element"></div></li>
                        
                        
                            </ul>
                        </li>
                    </ul>
                </div>
            </div>
        </div>
        
        
        <script>
    // Get all submenu anchors
    const menuItems = document.querySelectorAll('.sidebar-menu .submenu > a');
    
    // Add click event listener to each menu item
    menuItems.forEach(item => {
        item.addEventListener('click', (event) => {
            // Prevent default if needed (for demo purposes)
            event.preventDefault();

            // Remove 'active' class from all submenu items
            document.querySelectorAll('.submenu').forEach(submenu => {
                submenu.classList.remove('active');
            });

            // Add 'active' class to the clicked item's parent li
            item.parentElement.classList.add('active');
        });
    });
</script>

   <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
<script type="text/javascript">
function googleTranslateElementInit() {
  new google.translate.TranslateElement({
    pageLanguage: 'en',
    includedLanguages: 'hi,en',
    autoDisplay: false,
    multilanguagePage: true
  }, 'google_translate_element');
}
</script>

