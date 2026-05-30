import cv2
import os
import subprocess

def download_and_extract(url, output_dir, interval_sec=120):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    print(f"Downloading video from {url}...")
    video_path = "temp_stick_ranger.mp4"
    cmd = [
        '.\\yt-dlp.exe', 
        '-f', 'bestvideo[ext=mp4]/best[ext=mp4]',
        '-o', video_path,
        url
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if not os.path.exists(video_path):
        print(f"Error: Download failed. {result.stderr}")
        return
        
    print("Download complete. Extracting frames...")
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print("Error: Could not open video.")
        return
        
    fps = cap.get(cv2.CAP_PROP_FPS)
    print(f"Video FPS: {fps}")
    
    frame_interval = int(fps * interval_sec)
    if frame_interval == 0:
        frame_interval = 30
        
    frame_count = 0
    extracted_count = 0
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
            
        if frame_count % frame_interval == 0:
            filename = os.path.join(output_dir, f"frame_{extracted_count:03d}.jpg")
            cv2.imwrite(filename, frame)
            print(f"Saved {filename}")
            extracted_count += 1
            
        frame_count += 1
        
    cap.release()
    try:
        os.remove(video_path)
    except:
        pass
    print(f"Extraction complete. Extracted {extracted_count} frames to {output_dir}")

if __name__ == "__main__":
    # First video of the playlist
    url = "https://www.youtube.com/watch?v=IWFyJ_IifjY" 
    download_and_extract(url, "stick_ranger_frames", interval_sec=120)
