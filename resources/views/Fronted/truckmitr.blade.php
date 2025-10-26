@include('Fronted.header')

    <!-- BANNER SLIDER HERE  -->

    <section class="py-5 newpage-bg newpage">
        <div class="container py-5 py5">
            <center>
                <div class="row">
                    <div class="col-lg-12 col-sm-12">
                        <h1 class="text-white">Why TruckMitr</h1>
                        <ul class="breadcrumb">
                            <li><a href="{{url('/')}}">Home</a></li>
                            <li class="text-white">Why TruckMitr</li>
                        </ul>

                    </div>

                </div>
            </center>

        </div>

    </section>

    <!-- BANNER SLIDER HERE  -->


    <!-- TRICK MITR STRAT HERE SECTION   -->

        <section class="conatct-is pt-5">
        <div class="container">
            <div class="row">
                <div class="col-lg-9 col-sm-12 col-xl-9 m-auto">
                   <p>Truckmitr.com aims to bring together a comprehensive range of stakeholders in the Indian trucking industry. Connecting these various entities online can significantly streamline processes, enhance communication, and boost overall efficiency in the industry. Here's how you can specifically address the needs of each mentioned truckmitr:</p>
                </div>
            </div>
        </div>
    </section>



    <style>
.circle {
    width: 700px;
    height:700px;
    /* border: 2px solid black; */
    border-radius: 50%;
    position: relative;
    margin: 50px auto;
  }

  
  .item {
    position: absolute;
    /* width: 50px;
    height: 50px; */
    /* background-color: lightblue; */
    font-weight: bold;
    border-radius: 50%;
    text-align: center;
    z-index: 1;
    line-height: 20px;
    font-size: 14px;
    display: flex;
        justify-content: center;
        align-items: center;
    cursor: pointer;
    width: 100px;
    height: 100px;
  }

.custom-content img {
    width: 60px;
    border-radius: 100%;
    border: 2px solid #3f6ac2;
}
.custom-content p{
  line-height: 14px;
    font-size: 11px;
    font-weight: 500;
}
  /* Hide custom content by default */
.custom-content {
  display: none;
  box-shadow: rgba(149, 157, 165, 0.2) 0px 8px 24px;
  position: absolute;
  background:white;
  
  border-radius: 12px;
    top: 20px;
}

/* Show custom content on item hover */
.item:hover .custom-content {
    display: block;
    padding: 10px 10px;
    width: 180px;
}
  .center-text {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    font-size: 24px;
    font-weight: bold;
  }
  .add-text {
    position: absolute;
    bottom: -20px; /* Adjust vertical position */
    left: 50%;
    transform: translateX(-50%);
    font-size: 14px;
    color: gray;
  }
  .center-image {
    position: absolute;
    top: 55%;
    left: 55%;
    width: 115%;
    transform: translate(-50%, -50%);
  }
        .faq-container {
            margin: 20px;
        }
        .faq-section {
            margin-bottom: 20px;
            border-radius: 5px;
            overflow: hidden;
            background: #F4F4F4;
        }
        .faq-header {
            background-color: #F4F4F4;
            padding: 10px;
            cursor: pointer;
            display: flex;
            align-items: center;
        }
        .faq-content {
            display: none;
            padding:20px;
            border-top: 1px solid #e7e7e7;
        }
        .faq-header span{
          font-weight: 600;
        }
        .faq-header{
          color: #000;
        }
        
        .faq-content img {
          width: 100%;
        height: auto;
        margin-right: 10px;
        border-radius: 20px;
        }
        .faq-content p{
          font-size: 16px !important;
          padding: 15px 0px;
        }

        .faq-content.open {
            display: block;
        }

        .faq-header.open {
          color: #3F6AC2; /* Change this to your preferred color */
        }
    </style>

    <div class="faq-container d-block d-sm-none mb-5">
        <!-- FAQ Sections will be generated here -->
    </div>


<section class="pb-5 d-none d-sm-block">
  <div class="circle" id="circle">
    
  </div>
</section>

<script>
    // Function to create items and position them around the circle
    function createItems() {
      var circle = document.getElementById('circle');
      var radius = circle.offsetWidth / 2;
      var angle = 0;
      var increment = 360 / 20; // Adjusted for 20 items
  
      var itemTexts = [
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        ""
      ];
      
      var customContents = [
            { imageSrc: "{{url('public/front/assets/images/driver/Second-Hand.png')}}", title: 'Truck Body Builders', content: 'Connect truck body builders with truck owners and transporters. Provide a platform for showcasing their services and receiving orders.' },
            { imageSrc: "{{url('public/front/assets/images/driver/Fuel-Pumps.png')}}", title: 'Fuel Pumps', content: 'Integrate with fuel pumps to provide location-based fuel prices, track fuel expenses, and facilitate seamless payment options for truck owners.' },
            { imageSrc: "{{url('public/front/assets/images/driver/BatterySale.png')}}", title: 'Puncture Shops', content: 'Connect drivers with puncture repair services and offer a directory of puncture shops along trucking routes.' },
            { imageSrc: "{{url('public/front/assets/images/driver/Driver-Dhabas.png')}}", title: 'Driver Dhabas', content: 'Provide information on truck-friendly dhabas and rest areas. Allow for online ordering and delivery services for drivers on the road.' },
            { imageSrc: "{{url('public/front/assets/images/driver/Highway-Healthcare.png')}}", title: 'Highway Healthcare Providers (Doctors)', content: 'Connect healthcare providers with drivers, allowing for telemedicine consultations or information on nearby healthcare facilities.' },
            { imageSrc: "{{url('public/front/assets/images/driver/TrainingCenters.png')}}", title: 'Education/Training Centers', content: 'Offer a platform for driver training centers to connect with aspiring truck drivers. Provide resources for ongoing education and skill development.' },
            { imageSrc: "{{url('public/front/assets/images/tracks.png')}}", title: 'Finance Companies', content: 'Facilitate financing options for truck purchases, equipment, and working capital. Connect finance companies with truck buyers and businesses.' },
            { imageSrc: "{{url('public/front/assets/images/driver/BatterySale.png')}}", title: 'Tyre/Battery Sales', content: 'Create a marketplace for the sale of tyres and batteries. Provide information on product specifications and connect sellers with buyers.' },
            { imageSrc: "{{url('public/front/assets/images/driver/Puncture-Shops.png')}}", title: 'Truck Accessories', content: 'Connect truck accessory providers with truck owners. Showcase and sell accessories such as GPS devices, safety equipment, and more.' },
            { imageSrc: "{{url('public/front/assets/images/driver/TruckMechanic.png')}}", title: 'Truck Mechanic', content: 'Connect truck mechanics with drivers and transporters. Provide a platform for scheduling and managing maintenance and repair services.' },
            { imageSrc: "{{url('public/front/assets/images/driver/Second-Hand.png')}}", title: 'Second Hand Truck Market', content: 'Create a marketplace for buying and selling used trucks. Facilitate transactions, inspections, and documentation online.' },
            { imageSrc: "{{url('public/front/assets/images/driver/Scrapyard.png')}}", title: 'Truck Scrap Centers', content: 'Connect truck owners looking to dispose of old vehicles with scrap centers. Provide information on recycling and disposal options.' },
            { imageSrc: "{{url('public/front/assets/images/driver/Fitness-Center.png')}}", title: 'Truck Fitness Centers', content: 'Offer resources and partnerships for truck fitness and wellness. Connect drivers with fitness centers and programs.' },
            { imageSrc: "{{url('public/front/assets/images/driver/Driving-School.png')}}", title: 'Driving Training Schools', content: 'Connect aspiring drivers with training schools. Provide information on licensing requirements and facilitate enrollment.' },
            { imageSrc: "{{url('public/front/assets/images/driver/freight-agent.png')}}", title: 'Freight Agents', content: 'Facilitate connections between freight agents, transporters, and drivers. Provide tools for managing and tracking freight shipments.' },
            { imageSrc: "{{url('public/front/assets/images/Rectangle6.png')}}", title: 'Truck Drivers', content: 'Provide a platform for truck drivers to find jobs, connect with transporters, and access resources such as training and healthcare.' },
            { imageSrc: "{{url('public/front/assets/images/Rectangle6.png')}}", title: 'Transporters', content: 'Facilitate load matching, route optimization, and communication between transporters and drivers. Offer tools for fleet management and logistics.' },
            { imageSrc: "{{url('public/front/assets/images/Rectangle27.png')}}", title: 'Truck OEMs', content: 'Create a marketplace for OEMs to showcase and sell trucks and related equipment. Provide a platform for OEMs to engage with buyers and offer after-sales services.' },
            { imageSrc: "{{url('public/front/assets/images/Rectangle28.png')}}", title: 'Workshops', content: 'Connect workshops with truck owners and drivers for maintenance and repairs. Implement a rating system to help users find reliable service providers.' },
            { imageSrc: "{{url('public/front/assets/images/insurance1.png')}}", title: 'Insurance Companies', content: 'Offer an integrated platform for insurance companies to provide quotes, process claims, and offer insurance products tailored to the trucking industry.' }
        ];
  
      for (var i = 0; i < 20; i++) {
        var item = document.createElement('div');
        item.className = 'item';
        var modifiedTitle = itemTexts[i].replace('Second Hand Truck Market', 'Second Hand<br>Truck Market');
// Add more replacements as needed for other titles

item.innerHTML = modifiedTitle;

        
        // Create custom content element
        var customContent = document.createElement('div');
        customContent.className = 'custom-content';
        
        // Create image element
        var image = document.createElement('img');
        image.src = customContents[i].imageSrc;
        image.alt = customContents[i].title;
        customContent.appendChild(image);
        
        // Create title element
        var title = document.createElement('h6');
        title.textContent = customContents[i].title;
        customContent.appendChild(title);
        
        // Create content element
        var content = document.createElement('p');
        content.textContent = customContents[i].content;
        customContent.appendChild(content);
        
        // Append custom content to item
        item.appendChild(customContent);
        
        // Calculate position
        var x = Math.round(radius + radius * Math.cos(angle * Math.PI / 180));
        var y = Math.round(radius + radius * Math.sin(angle * Math.PI / 180));
  
        // Position the item
        item.style.left = x - (item.offsetWidth / 2) + 'px';
        item.style.top = y - (item.offsetHeight / 2) + 'px';
  
        // Append the item to the circle
        circle.appendChild(item);
  
        // Increment angle for the next item
        angle += increment;
      }
  
      // Add center image
      var centerImage = document.createElement('img');
      centerImage.className = 'center-image';
      centerImage.src = "{{url('public/front/assets/images/Group03.png')}}" // Replace 'your-image-url.jpg' with the URL of your image
      centerImage.alt = 'Center Image';
      circle.appendChild(centerImage);
    }
  
    // Call the function when the page loads
    window.onload = createItems;
  </script>

<script>
        const customContents = [
            { imageSrc: "{{url('public/front/assets/images/driver/Second-Hand.png')}}" title: 'Truck Body Builders', content: 'Connect truck body builders with truck owners and transporters. Provide a platform for showcasing their services and receiving orders.'},
            { imageSrc: "{{url('public/front/assets/images/driver/Fuel-Pumps.png')}}", title: 'Fuel Pumps', content: 'Integrate with fuel pumps to provide location-based fuel prices, track fuel expenses, and facilitate seamless payment options for truck owners.' },
            { imageSrc: "{{url('public/front/assets/images/driver/BatterySale.png')}}", title: 'Puncture Shops', content: 'Connect drivers with puncture repair services and offer a directory of puncture shops along trucking routes.' },
            { imageSrc: "{{url('public/front/assets/images/driver/Driver-Dhabas.png')}}", title: 'Driver Dhabas', content: 'Provide information on truck-friendly dhabas and rest areas. Allow for online ordering and delivery services for drivers on the road.' },
            { imageSrc: "{{url('public/front/assets/images/driver/Highway-Healthcare.png')}}", title: 'Highway Healthcare Providers (Doctors)', content: 'Connect healthcare providers with drivers, allowing for telemedicine consultations or information on nearby healthcare facilities.' },
            { imageSrc: 'assets/images/driver/TrainingCenters.png', title: 'Education/Training Centers', content: 'Offer a platform for driver training centers to connect with aspiring truck drivers. Provide resources for ongoing education and skill development.' },
            { imageSrc: 'assets/images/tracks.png', title: 'Finance Companies', content: 'Facilitate financing options for truck purchases, equipment, and working capital. Connect finance companies with truck buyers and businesses.' },
            { imageSrc: 'assets/images/driver/BatterySale.png', title: 'Tyre/Battery Sales', content: 'Create a marketplace for the sale of tyres and batteries. Provide information on product specifications and connect sellers with buyers.' },
            { imageSrc: 'assets/images/driver/Puncture-Shops.png', title: 'Truck Accessories', content: 'Connect truck accessory providers with truck owners. Showcase and sell accessories such as GPS devices, safety equipment, and more.' },
            { imageSrc: 'assets/images/driver/TruckMechanic.png', title: 'Truck Mechanic', content: 'Connect truck mechanics with drivers and transporters. Provide a platform for scheduling and managing maintenance and repair services.' },
            { imageSrc: 'assets/images/driver/Second-Hand.png', title: 'Second Hand Truck Market', content: 'Create a marketplace for buying and selling used trucks. Facilitate transactions, inspections, and documentation online.' },
            { imageSrc: 'assets/images/driver/Scrapyard.png', title: 'Truck Scrap Centers', content: 'Connect truck owners looking to dispose of old vehicles with scrap centers. Provide information on recycling and disposal options.' },
            { imageSrc: 'assets/images/driver/Fitness-Center.png', title: 'Truck Fitness Centers', content: 'Offer resources and partnerships for truck fitness and wellness. Connect drivers with fitness centers and programs.' },
            { imageSrc: 'assets/images/driver/Driving-School.png', title: 'Driving Training Schools', content: 'Connect aspiring drivers with training schools. Provide information on licensing requirements and facilitate enrollment.' },
            { imageSrc: 'assets/images/driver/freight-agent.png', title: 'Freight Agents', content: 'Facilitate connections between freight agents, transporters, and drivers. Provide tools for managing and tracking freight shipments.' },
            { imageSrc: 'assets/images/Rectangle6.png', title: 'Truck Drivers', content: 'Provide a platform for truck drivers to find jobs, connect with transporters, and access resources such as training and healthcare.' },
            { imageSrc: 'assets/images/Rectangle6.png', title: 'Transporters', content: 'Facilitate load matching, route optimization, and communication between transporters and drivers. Offer tools for fleet management and logistics.' },
            { imageSrc: 'assets/images/Rectangle27.png', title: 'Truck OEM’s', content: 'Create a marketplace for OEMs to showcase and sell trucks and related equipment. Provide a platform for OEMs to engage with buyers and offer after-sales services.' },
            { imageSrc: 'assets/images/Rectangle28.png', title: 'Workshops', content: 'Connect workshops with truck owners and drivers for maintenance and repairs. Implement a rating system to help users find reliable service providers.' },
            { imageSrc: 'assets/images/insurance1.png', title: 'Insurance Companies', content: 'Offer an integrated platform for insurance companies to provide quotes, process claims, and offer insurance products tailored to the trucking industry.' }
        ];

        const faqContainer = document.querySelector('.faq-container');

        customContents.forEach((item, index) => {
            const faqSection = document.createElement('div');
            faqSection.classList.add('faq-section');

            const faqHeader = document.createElement('div');
            faqHeader.classList.add('faq-header');
            if (index === 0) {
                faqHeader.classList.add('open');
            }

            const faqTitle = document.createElement('span');
            faqTitle.textContent = item.title;

            faqHeader.appendChild(faqTitle);
            faqSection.appendChild(faqHeader);

            const faqContent = document.createElement('div');
            faqContent.classList.add('faq-content');
            if (index === 0) {
                faqContent.classList.add('open');
            }
            faqContent.innerHTML = `<img src="${item.imageSrc}" alt="${item.title}"><p>${item.content}</p>`;

            faqSection.appendChild(faqContent);
            faqContainer.appendChild(faqSection);
        });

        document.querySelectorAll('.faq-header').forEach(header => {
            header.addEventListener('click', () => {
                const content = header.nextElementSibling;
                const isOpen = content.classList.contains('open');

                // Close all open contents
                document.querySelectorAll('.faq-content').forEach(content => content.classList.remove('open'));
                document.querySelectorAll('.faq-header').forEach(header => header.classList.remove('open'));

                // Open the clicked one if it was not open
                if (!isOpen) {
                    content.classList.add('open');
                    header.classList.add('open');
                }
            });
        });
    </script>


@include('Fronted.footer')