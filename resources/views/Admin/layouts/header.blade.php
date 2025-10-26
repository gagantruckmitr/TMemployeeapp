<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=0">
    <title>Admin Dashboard</title>
    <link rel="shortcut icon" href="{{url('public/assets/img/favicon.png')}}">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,400;0,500;0,700;0,900;1,400;1,500;1,700&display=swap" rel="stylesheet">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,100;1,200;1,300;1,400;1,500;1,600;1,700;1,800;1,900&display=swap" rel="stylesheet">

    <link rel="stylesheet" href="{{ URL('public/assets/plugins/bootstrap/css/bootstrap.min.css') }}">
    <link rel="stylesheet" href="{{ URL('public/assets/plugins/feather/feather.css') }}">
    <link rel="stylesheet" href="{{ URL('public/assets/plugins/icons/flags/flags.css') }}">
    <link rel="stylesheet" href="{{ URL('public/assets/plugins/fontawesome/css/fontawesome.min.css') }}">
    <link rel="stylesheet" href="{{ URL('public/assets/plugins/fontawesome/css/all.min.css') }}">
    <link rel="stylesheet" href="{{ URL('public/assets/plugins/lightbox/glightbox.min.css') }}">
    <link rel="stylesheet" href="{{ URL('public/assets/plugins/datatables/datatables.min.css') }}">
    <link rel="stylesheet" href="{{ URL('public/assets/css/style.css') }}">
    <link rel="stylesheet" href="{{ URL('public/assets/plugins//toastr/toatr.css') }}">
    <link rel="stylesheet" href="{{ URL('public/assets/plugins/select2/css/select2.min.css') }}">
    <link rel="stylesheet" href="{{ URL('public/assets/plugins/summernote/summernote-bs4.min.css') }}">
    <link rel="icon" type="image/x-icon" href="{{url('public/front/assets/images/favicon.png')}}">

    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
</head>
<style>
/* All mobile devices: phones and small tablets */
        @media only screen and (max-width: 768px) {
            .small, small {
                font-size: 1.2em;
                
            }
        }

        /* Optional: Very small phones (e.g. iPhone SE) */
        @media only screen and (max-width: 480px) {
            .small, small {
                font-size: 1.2em;
               
            }
        }
	</style>
<body>

    <div class="main-wrapper">

        <div class="header">

            <div class="header-left">
                <a href="" class="logo">
                    <img src="{{url('public/assets/img/logo.png')}}" alt="Logo">
                </a>
                <a href="/admin/dashboard" class="logo logo-small">
                    <img src="{{url('public/assets/img/logo-small.png')}}" alt="Logo" width="30" height="30">
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


                <li class="nav-item dropdown has-arrow new-user-menus">
                    <a href="#" class="dropdown-toggle nav-link" data-bs-toggle="dropdown">
                        <span class="user-img">
                            @if (Session::get('role') === 'telecaller')
 <img class="rounded-circle" src="{{ url('public/noimg.png') }}" width="31" alt="Default Image">
                            @elseif (Session::get('role') === 'admin')
                            <img class="rounded-circle" src="{{url('public/images/1735122057.png')}}" width="31"
                                alt="Soeng Souy">
                                  @endif
                            <div class="user-text">
                                <h6 style="margin-top:10px;">@if (Session::has('name') || Session::has('role'))
                                    {{ Session::get('name') }}
                                </h6>
                                <p class="text-muted mb-0">{{ Session::get('role') }}</p>
                                @else
                                @endif
                            </div>
                        </span>
                    </a>
                    <div class="dropdown-menu">


                        <a class="dropdown-item" href="{{url('admin_logouts')}}">Logout</a>
                    </div>
                </li>

            </ul>

        </div>


@if (Session::get('role') === 'telecaller')

   
 <div class="sidebar" id="sidebar">
            <div class="sidebar-inner slimscroll">
                <div id="sidebar-menu" class="sidebar-menu">
                    <ul>
                        <li class="menu-title">
                            <span>Main Menu</span>
                        </li>
                    
                        <li>
                            <a href="{{ route('telecaller.callback-requests.index') }}"
                                class="{{ request()->is('telecaller/callback-requests*') ? 'active' : '' }}"><i
                                    class="fas fa-phone"></i> <span> Callback Requests </span></a>
                        </li>

                        <li>
                            <a href="{{url('admin_logouts')}}"><i class="fas fa-sign-out-alt"></i> <span>Logout</span></a>
                        </li>

                    </ul>
                    </li>
                    </ul>
                </div>
            </div>
        </div>


	
	
	
  @elseif (Session::get('role') === 'manager')

         <div class="sidebar" id="sidebar">
            <div class="sidebar-inner slimscroll">
                <div id="sidebar-menu" class="sidebar-menu">
                    <ul>
                        <li class="menu-title">
                            <span>Main Menu</span>
                        </li>
                    
                        <li>
                            <a href="{{ route('admin.callback-requests.index') }}"
                                class="{{ request()->is('admin/callback-requests*') ? 'active' : '' }}"><i
                                    class="fas fa-phone"></i> <span> Callback Requests </span></a>
                        </li>

                        <li>
                            <a href="{{url('admin_logouts')}}"><i class="fas fa-sign-out-alt"></i> <span>Logout</span></a>
                        </li>

                    </ul>
                    </li>
                    </ul>
                </div>
            </div>
        </div>
   	
	
	
   
@elseif (Session::get('role') === 'admin')

 <div class="sidebar" id="sidebar">
            <div class="sidebar-inner slimscroll">
                <div id="sidebar-menu" class="sidebar-menu">
                    <ul>
                        <li class="menu-title">
                            <span>Main Menu</span>
                        </li>
                        <li><a href="{{url('admin/dashboard')}}" class="{{ request()->is('admin/dashboard') ? 'active' : '' }}"><i class="feather-grid"></i> <span>Dashboard</span></a></li>

                        <li class="submenu">
                            <a href="#"><i class="fas fa-tag"></i> <span>OEM Brand </span> <span
                                    class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('admin/brand')}}" class="{{ request()->is('admin/brand') ? 'active' : '' }}">Brand List</a></li>

                            </ul>
                        </li>

                        <li class="submenu">
                            <a href="#"><i class="fas fa-filter"></i> <span>OEM Filter</span> <span
                                    class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('admin/budget')}}" class="{{ request()->is('admin/budget') ? 'active' : '' }}">Budget</a></li>
                                <li><a href="{{url('admin/fuel-type')}}" class="{{ request()->is('admin/fuel-type') ? 'active' : '' }}">Fuel Type</a></li>
                                <li><a href="{{url('admin/vehicle-application')}}" class="{{ request()->is('admin/vehicle-application') ? 'active' : '' }}">Vehicle Application</a></li>
                                <li><a href="{{url('admin/gvm')}}" class="{{ request()->is('admin/gvm') ? 'active' : '' }}">GVW (Tons)</a></li>
                                <li><a href="{{url('admin/vehicletype')}}" class="{{ request()->is('admin/vehicletype') ? 'active' : '' }}">Vehicle Type</a></li>
                                <li><a href="{{url('admin/tyres-count')}}" class="{{ request()->is('admin/tyres-count') ? 'active' : '' }}">Tyres Count</a></li>

                            </ul>
                        </li>
                        <li class="submenu {{ request()->is('admin/notifications*') ? 'active' : '' }}">
                            <a href="#"><i class="fas fa-bell"></i> <span> Notifications </span> <span class="menu-arrow"></span></a>
                            <ul>
                                <li>
                                    <a href="{{ url('admin/notifications') }}" class="{{ request()->is('admin/notifications') ? 'active' : '' }}">
                                        View Notifications
                                    </a>
                                </li>
                                <li>
                                    <a href="{{ url('admin/notifications/create') }}" class="{{ request()->is('admin/notifications/create') ? 'active' : '' }}">
                                        Send Notification
                                    </a>
                                </li>
                            </ul>
                        </li>
                        <li class="submenu {{ request()->is('admin/banners*') ? 'active' : '' }}">
                            <a href="#"><i class="fas fa-images"></i> <span> Banners </span> <span class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{ route('admin.banners.index') }}" class="{{ request()->is('admin/banners') ? 'active' : '' }}">View Banners</a></li>
                                <li><a href="{{ route('admin.banners.create') }}" class="{{ request()->is('admin/banners/create') ? 'active' : '' }}">Add Banner</a></li>
                            </ul>
                        </li>
                        <li class="submenu {{ request()->is('admin/popup-messages*') ? 'active' : '' }}">
                            <a href="#"><i class="fas fa-comment-alt"></i> <span> Popup Messages </span> <span
                                    class="menu-arrow"></span></a>
                            <ul>
                                <li>
                                    <a href="{{ route('admin.popup-messages.index') }}"
                                        class="{{ request()->is('admin/popup-messages') ? 'active' : '' }}">
                                        View Messages
                                    </a>
                                </li>
                                <li>
                                    <a href="{{ route('admin.popup-messages.create') }}"
                                        class="{{ request()->is('admin/popup-messages/create') ? 'active' : '' }}">
                                        Add Message
                                    </a>
                                </li>
                            </ul>
                        </li>
                        <li class="submenu {{ request()->is('admin/call-logs*') ? 'active' : '' }}">
                            <a href="#"><i class="fas fa-comment-alt"></i> <span> Call Logs Tracking </span> <span
                                    class="menu-arrow"></span></a>
                            <ul>
                                <li>
                                    <a href="{{ route('admin.call-logs.transporters') }}"
                                        class="{{ request()->is('admin/call-logs/transporters') ? 'active' : '' }}">
                                        Call Log Transporters
                                    </a>
                                </li>

                                <li>
                                    <a href="{{ route('admin.call-logs.drivers') }}"
                                        class="{{ request()->is('admin/call-logs/drivers') ? 'active' : '' }}">
                                        Call Log Driver
                                    </a>
                                </li>
                            </ul>
                        </li>
                        <li>
                            <a href="{{ route('admin.callback-requests.index') }}"
                                class="{{ request()->is('admin/callback-requests*') ? 'active' : '' }}"><i
                                    class="fas fa-phone"></i> <span> Callback Requests </span></a>
                        </li>
                        <!-- Payment Management -->
                        <li class="submenu {{ request()->is('admin/payments*') ? 'active' : '' }}">
                            <a href="#"><i class="fas fa-credit-card"></i> <span> Payments </span> <span class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{ route('admin.payment.index') }}">View Payments</a></li>
                                <li><a href="{{ route('admin.payment.failed') }}">View Failed Payments</a></li>
                            </ul>
                        </li>

                        <!-- Subscription Management -->
                        <li class="submenu {{ request()->is('admin/subscription*') ? 'active' : '' }}">
                            <a href="#"><i class="fas fa-cogs"></i> <span> Subscription </span> <span class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{ route('admin.subscription.index') }}">View Subscriptions</a></li>
                                <li><a href="{{ route('admin.subscription.create') }}">Create Subscription</a></li>
                            </ul>
                        </li>
                        <!-- User Management -->
                        <li class="submenu {{ request()->is('admin/users*') ? 'active' : '' }}">
                            <a href="#"><i class="fas fa-cogs"></i> <span> Users </span> <span class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{ route('admin.users.index') }}">View Users</a></li>
                            </ul>
                        </li>

                        <!-- Career Menu -->
                        <li class="submenu {{ request()->is('admin/career*') ? 'active' : '' }}">
                            <a href="#"><i class="fas fa-briefcase"></i> <span> Career </span> <span class="menu-arrow"></span></a>
                            <ul>
                                <li>
                                    <a href="{{ url('admin/career') }}" class="{{ request()->is('admin/career') ? 'active' : '' }}">
                                        View Careers
                                    </a>
                                </li>
                                <li>
                                    <a href="{{ url('admin/career/create') }}" class="{{ request()->is('admin/career/create') ? 'active' : '' }}">
                                        Add Career
                                    </a>
                                </li>
                            </ul>
                        </li>

                        <li class="submenu {{ request()->is('admin/inquery*') ? 'active' : '' }}">
                            <a href="#"><i class="fas fa-briefcase"></i> <span> Enquiry </span> <span class="menu-arrow"></span></a>
                            <ul>
                                <li>
                                    <a href="{{ url('admin/inquery') }}" class="{{ request()->is('admin/inquery') ? 'active' : '' }}">
                                        View Enquiries
                                    </a>
                                </li>

                            </ul>
                        </li>


                        <li class="submenu">
                            <a href="#"><i class="fas fa-truck"></i> <span> Truck Listings </span> <span
                                    class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('admin/vehicletype')}}" class="{{ request()->is('admin/vehicletype') ? 'active' : '' }}">Vehicle Type</a></li>
                                <li><a href="{{url('admin/add-truck')}}" class="{{ request()->is('admin/add-truck') ? 'active' : '' }}">Add Truck</a></li>
                                <li><a href="{{url('admin/truck-list')}}" class="{{ request()->is('admin/truck-list') ? 'active' : '' }}">Truck List</a></li>

                            </ul>
                        </li>



                        <li class="submenu">
                            <a href="#"><i class="fas fa-user-shield"></i> <span> Driver Management </span> <span
                                    class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('admin/driver-list')}}" class="{{request()->routeIs('driver_list')?'active':''}}">Driver List</a></li>
                            </ul>
                        </li>

                        <li class="submenu">
                            <a href="#"><i class="fas fa-road"></i> <span> Transporter </span> <span
                                    class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('admin/transporter')}}" class="{{ request()->is('admin/transporter') ? 'active' : '' }}">View List</a></li>

                            </ul>
                        </li>

                        <li class="submenu">
                            <a href="#"><i class="fas fa-graduation-cap"></i> <span>DTS </span> <span
                                    class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('admin/view-truck-institute')}}" class="{{ request()->is('admin/view-truck-institute') ? 'active' : '' }}">DTS List</a></li>

                            </ul>
                        </li>

                        <li class="submenu">
                            <a href="#"><i class="fas fa-briefcase"></i> <span> Job</span> <span
                                    class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('admin/jobs')}}" class="{{ request()->is('admin/jobs') ? 'active' : '' }}">Job List</a></li>
								<li><a href="{{url('admin/active-jobs')}}" class="{{ request()->is('admin/active-jobs') ? 'active' : '' }}">Active Jobs List</a></li>
                                <li><a href="{{url('admin/inactive-jobs')}}" class="{{ request()->is('admin/inactive-jobs') ? 'active' : '' }}">Inactive Jobs List</a></li>
                                <li><a href="{{url('admin/expired-jobs')}}" class="{{ request()->is('admin/expired-jobs') ? 'active' : '' }}">Expired Jobs List</a></li>
								
                                <li><a href="{{url('admin/pending-for-approval-jobs')}}" class="{{ request()->is('admin/pending-for-approval-jobs') ? 'active' : '' }}">Pending for Approval</a></li>
                                <li><a href="{{url('admin/master-jobs')}}" class="{{ request()->is('admin/master-jobs') ? 'active' : '' }}">Master Job</a></li>
                            </ul>

                        </li>



                        <li class="submenu">
                            <a href="#"><i class="fas fa-video"></i> <span>Video </span> <span
                                    class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('admin/module')}}" class="{{ request()->is('admin/module') ? 'active' : '' }}">Module</a></li>
                                <li><a href="{{url('admin/module-topic')}}" class="{{ request()->is('admin/module-topic') ? 'active' : '' }}">Module Topic</a></li>
                                <li><a href="{{url('admin/video')}}" class="{{ request()->is('admin/video') ? 'active' : '' }}">Video</a></li>
                                <li><a href="{{url('admin/health-hygiene')}}" class="{{ request()->is('admin/health-hygiene') ? 'active' : '' }}">Health & Hygiene</a></li>

                            </ul>
                        </li>
                        <li class="submenu">
                            <a href="#"><i class="fas fa-question-circle"></i> <span>Quiz</span> <span
                                    class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('admin/add-quiz')}}" class="{{ request()->is('admin/add-quiz') ? 'active' : '' }}">Add Quiz</a></li>
                                <li><a href="{{url('admin/quiz')}}" class="{{ request()->is('admin/quiz') ? 'active' : '' }}">View Quiz</a></li>

                            </ul>
                        </li>

                        <li class="submenu">
                            <a href="#"><i class="fas fa-blog"></i> <span> Blogs </span> <span class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('admin/blog-category')}}" class="{{ request()->is('admin/blog-category') ? 'active' : '' }}">Add Blog Category</a></li>
                                <li><a href="{{url('admin/add-blog')}}" class="{{ request()->is('admin/add-blog') ? 'active' : '' }}">Add Blog</a></li>
                                <li><a href="{{url('admin/blogs')}}" class="{{ request()->is('admin/blogs') ? 'active' : '' }}">Blogs List</a></li>
                            </ul>
                        </li>

                        <li class="submenu">
                            <a href="#"><i class="fas fa-blog"></i> <span> Shipper </span> <span class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('admin/shipper/view-shipper')}}" class="{{ request()->is('admin/shipper/view-shipper') ? 'active' : '' }}">View Shipper</a></li>

                            </ul>
                        </li>

                        <li class="submenu">
                            <a href="#"><i class="fas fa-blog"></i> <span> Trucker </span> <span class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('admin/trucker/view-trucker')}}" class="{{ request()->is('admin/trucker/view-trucker') ? 'active' : '' }}">View Trucker</a></li>

                            </ul>
                        </li>

                        <li class="submenu">
                            <a href="#"><i class="fas fa-blog"></i> <span> Employee </span> <span class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('admin/add-employee')}}" class="{{ request()->is('admin/add-employee') ? 'active' : '' }}">Add Employee</a></li>
                                <li><a href="{{url('admin/employee')}}" class="{{ request()->is('admin/employee') ? 'active' : '' }}">Employee List</a></li>
                            </ul>
                        </li>

                        <li class="submenu">
                            <a href="#"><i class="fas fa-blog"></i> <span> Load Price </span> <span class="menu-arrow"></span></a>
                            <ul>
                                <li><a href="{{url('admin/add-price')}}" class="{{ request()->is('admin/add-price') ? 'active' : '' }}">Add Price</a></li>
                                <li><a href="{{url('admin/view-price')}}" class="{{ request()->is('admin/view-price') ? 'active' : '' }}">Price List</a></li>
                            </ul>
                        </li>
                        <li>
                            <a href="{{url('admin_logouts')}}"><i class="fas fa-sign-out-alt"></i> <span>Logout</span></a>
                        </li>

                    </ul>
                    </li>
                    </ul>
                </div>
            </div>
        </div>


  

        @endif






       
        <!--Popup-->

        <script>
            // Get all submenu anchors
            const menuItems = document.querySelectorAll('.sidebar-menu .submenu > a');

            // Add click event listener to each menu item
            menuItems.forEach(item => {
                item.addEventListener('click', (event) => {
                    event.preventDefault();

                    const parentLi = item.parentElement;
                    const submenuUl = parentLi.querySelector('ul');

                    if (parentLi.classList.contains('active')) {
                        // Close current submenu
                        parentLi.classList.remove('active');
                        if (submenuUl) submenuUl.style.display = 'none';
                    } else {
                        // Close others
                        document.querySelectorAll('.submenu').forEach(submenu => {
                            submenu.classList.remove('active');
                            const ul = submenu.querySelector('ul');
                            if (ul) ul.style.display = 'none';
                        });
                        // Open current
                        parentLi.classList.add('active');
                        if (submenuUl) submenuUl.style.display = 'block';
                    }
                });
            });
        </script>