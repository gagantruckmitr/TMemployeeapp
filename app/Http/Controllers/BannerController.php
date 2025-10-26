<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\File;
use App\Models\Banner;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Session;

class BannerController extends Controller
{
    public function index()
    {
		if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $banners = Banner::orderBy('sort_order', 'asc')->orderBy('created_at', 'desc')->get();
        return view('Admin.banners.index', compact('banners'));
    }

    public function create()
    {
		if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        return view('Admin.banners.create');
    }

    public function store(Request $request)
    {
		if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'media_type' => 'required|in:image,video',
            'media' => 'nullable|file',
            'thumbnail' => 'nullable|string', // base64 thumbnail
            'status' => 'boolean'
        ]);

        $mediaPath = null;
        $thumbnailDbPath = null;

        if ($request->hasFile('media')) {
            $file = $request->file('media');

            if ($request->media_type === 'image') {
                if ($file->getSize() > 2 * 1024 * 1024) {
                    return back()->withErrors(['media' => 'Image size must be less than 2MB.'])->withInput();
                }

                $imageInfo = getimagesize($file->getPathname());
                if ($imageInfo[0] !== 1252 || $imageInfo[1] !== 724) {
                    return back()->withErrors(['media' => 'Image dimensions must be exactly 1252 × 724 pixels.'])->withInput();
                }

                $fileName = time() . '_' . Str::random(10) . '.' . $file->getClientOriginalExtension();
                $mediaPath = 'banners/images/' . $fileName;
                $file->move(public_path('banners/images'), $fileName);
            } else {
                if ($file->getSize() > 50 * 1024 * 1024) {
                    return back()->withErrors(['media' => 'Video size must be less than 50MB.'])->withInput();
                }

                $fileName = time() . '_' . Str::random(10) . '.' . $file->getClientOriginalExtension();
                $mediaPath = 'banners/videos/' . $fileName;
                $file->move(public_path('banners/videos'), $fileName);
            }
        }

        if ($request->filled('thumbnail')) {
            $thumbnailData = str_replace('data:image/jpeg;base64,', '', $request->thumbnail);
            $thumbnailData = base64_decode($thumbnailData);

            $thumbnailFile = time() . '_' . Str::random(10) . '.jpg';
            $thumbnailPath = public_path('banners/thumbnails/' . $thumbnailFile);

            if (!is_dir(public_path('banners/thumbnails'))) {
                mkdir(public_path('banners/thumbnails'), 0755, true);
            }

            file_put_contents($thumbnailPath, $thumbnailData);
            $thumbnailDbPath = 'banners/thumbnails/' . $thumbnailFile;
        }

        Banner::create([
            'title'          => $request->title,
            'description'    => $request->description,
            'media_type'     => $request->media_type,
            'media_path'     => $mediaPath,
            'thumbnail_path' => $thumbnailDbPath,
            'status'         => $request->status ?? 1
        ]);

        return redirect()->route('admin.banners.index')->with('success', 'Banner created successfully!');
    }



    public function edit($id)
    {
		if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $banner = Banner::findOrFail($id);
        return view('Admin.banners.edit', compact('banner'));
    }

    /**
     * Update an existing banner.
     */
    public function update(Request $request, $id)
    {
		if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $banner = Banner::findOrFail($id);

        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'media_type' => 'required|in:image,video',
            'user_type' => 'required|in:transporter,driver',
            'media' => 'nullable|file',
            'status' => 'required|boolean'
        ]);

        $mediaPath = $banner->media_path;
        $thumbnailPath = $banner->thumbnail_path;

        if ($request->hasFile('media')) {
            $file = $request->file('media');

            if ($request->media_type === 'image') {
                $request->validate([
                    'media' => 'image|mimes:jpg,jpeg,png,gif,webp|max:2048',
                ]);

                $imageInfo = getimagesize($file);
                if ($imageInfo[0] != 1252 || $imageInfo[1] != 724) {
                    return back()->withErrors(['media' => 'Image must be exactly 1252x724 pixels.'])->withInput();
                }
            } else {
                $request->validate([
                    'media' => 'mimetypes:video/mp4,video/avi,video/mov,video/webm|max:51200',
                ]);
            }

            // Delete old files
            if ($mediaPath && file_exists(public_path($mediaPath))) {
                unlink(public_path($mediaPath));
            }
            if ($thumbnailPath && file_exists(public_path($thumbnailPath))) {
                unlink(public_path($thumbnailPath));
            }

            if ($request->media_type === 'video') {
                // === VIDEO path ===
                $fileName = time() . '_' . \Str::random(10) . '.' . $file->getClientOriginalExtension();
                $file->move(public_path('banners/videos'), $fileName);
                $mediaPath = 'banners/videos/' . $fileName;

                // Generate thumbnail if provided
                if ($request->filled('thumbnail')) {
                    $thumbnailData = str_replace('data:image/jpeg;base64,', '', $request->thumbnail);
                    $thumbnailData = base64_decode($thumbnailData);

                    if (!is_dir(public_path('banners/thumbnails'))) {
                        mkdir(public_path('banners/thumbnails'), 0755, true);
                    }

                    $thumbnailFile = time() . '_' . \Str::random(10) . '.jpg';
                    file_put_contents(public_path('banners/thumbnails/' . $thumbnailFile), $thumbnailData);

                    $thumbnailPath = 'banners/thumbnails/' . $thumbnailFile;
                } else {
                    $thumbnailPath = null;
                }
            } else {
                // === IMAGE path ===
                $fileName = time() . '_' . $file->getClientOriginalName();
                $file->move(public_path('banners/images'), $fileName);
                $mediaPath = 'banners/images/' . $fileName;

                // Optional thumbnail
                $thumbnailFilename = 'thumb_' . $fileName;
                $thumbnailPath = 'banners/images/' . $thumbnailFilename;

                $img = \Image::make($file)->resize(300, 173, function ($constraint) {
                    $constraint->aspectRatio();
                });
                $img->save(public_path($thumbnailPath));
            }
        }

        $banner->update([
            'title' => $request->title,
            'description' => $request->description,
            'media_type' => $request->media_type,
            'user_type' => $request->user_type,
            'media_path' => $mediaPath,
            'thumbnail_path' => $thumbnailPath,
            'status' => $request->status,
        ]);

        return redirect()->route('admin.banners.index')
            ->with('success', 'Banner updated successfully.');
    }


    public function destroy($id)
    {
		if (Session::get('role') != 'admin') {
            return redirect('admin');
        }
        $banner = Banner::findOrFail($id);

        // Delete media files
        if ($banner->media_path && file_exists(public_path($banner->media_path))) {
            unlink(public_path($banner->media_path));
        }

        $banner->delete();

        return redirect()->route('admin.banners.index')->with('success', 'Banner deleted successfully!');
    }

    public function toggleStatus($id)
    {
        $banner = Banner::findOrFail($id);
        $banner->update(['status' => !$banner->status]);

        return redirect()->route('admin.banners.index')->with('success', 'Banner status updated successfully!');
    }

    private function ensureDirectoriesExist()
    {
        $directories = [
            public_path('banners/images'),
            public_path('banners/videos')
        ];

        foreach ($directories as $directory) {
            if (!is_dir($directory)) {
                mkdir($directory, 0755, true);
            }
        }
    }
}
