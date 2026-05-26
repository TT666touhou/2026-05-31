import cv2
import os
import subprocess

def download_and_extract(url, start_time, end_time, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    print("Downloading video segment using standalone yt-dlp...")
    video_path = "temp_sword_video.mp4"
    cmd = [
        '.\\yt-dlp.exe', 
        '-f', 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
        '--download-sections', f"*{start_time}-{end_time}",
        '-o', video_path,
        url
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error downloading segment: {result.stderr}")
        return
        
    print("Download complete. Extracting frames...")
    
    if not os.path.exists(video_path):
        print(f"Error: Downloaded video not found at {video_path}")
        return
        
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print("Error: Could not open downloaded video.")
        return
        
    fps = cap.get(cv2.CAP_PROP_FPS)
    print(f"Video FPS: {fps}")
    
    frame_count = 0
    extracted_count = 0
    
    sample_rate = max(1, int(fps / 15)) # Extract 15 frames per second for detailed analysis
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
            
        if frame_count % sample_rate == 0:
            filename = os.path.join(output_dir, f"frame_{extracted_count:03d}.jpg")
            cv2.imwrite(filename, frame)
            extracted_count += 1
            
        frame_count += 1
        
    cap.release()
    
    try:
        os.remove(video_path)
    except Exception as e:
        print(f"Warning: Could not remove temp video: {e}")
        
    print(f"Extraction complete. Extracted {extracted_count} frames to {output_dir}")

if __name__ == "__main__":
    url = "https://www.youtube.com/watch?v=IWFyJ_IifjY"
    # Extract from 1:44 to 1:48 (104s to 108s)
    download_and_extract(url, 104.0, 108.0, "sword_frames")
