import json

def get_priority(text_line):
    """
    Returns priority value based on text content.
    Lower numbers = higher priority.
    """
    if "[[Mood" in text_line:
        return 1
    if "Aquire {" in text_line:
        return 2
    elif "[[Fans]]" in text_line:
        return 3
    elif "[[bond" in text_line:
        return 4
    elif "[[possible]]" in text_line:
        return 5
    elif "[[hint]]" in text_line:
        return 6
    elif "[[Wit" in text_line:
        return 8
    elif "[[Guts" in text_line:
        return 9
    elif "[[Power" in text_line:
        return 10
    elif "[[Stamina" in text_line:
        return 11
    elif "[[Speed" in text_line:
        return 12
    elif "[[sp+" in text_line:
        return 13
    elif "[[Energy" in text_line:
        return 14
    else:
        return 7  # Nothing matches

def process_json_file(input_file, output_file=None):
    """
    Process JSON file according to specified priority rules.
    
    Args:
        input_file (str): Path to input JSON file
        output_file (str, optional): Path to output JSON file. If None, overwrites input file.
    """
    
    # Read the JSON file
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        print(f"Successfully loaded JSON file: {input_file}")
    except FileNotFoundError:
        print(f"Error: File '{input_file}' not found.")
        return
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON in file '{input_file}'.")
        return
    
    # Counters for logging
    items_processed = 0
    events_processed = 0
    texts_processed = 0
    texts_changed = 0
    
    print(f"Starting to process {len(data) if isinstance(data, list) else 1} top-level items...")
    
    # Handle both list and single object JSON structures
    items_to_process = data if isinstance(data, list) else [data]
    
    # Process each item
    for item_idx, item in enumerate(items_to_process):
        if 'events' in item and isinstance(item['events'], list):
            items_processed += 1
            print(f"\nProcessing item {item_idx + 1}: Found {len(item['events'])} events")
            
            # Loop through events array
            for event_idx, event in enumerate(item['events']):
                if 'text' in event and isinstance(event['text'], list):
                    events_processed += 1
                    print(f"  Event {event_idx + 1}: Found {len(event['text'])} text entries")
                    
                    # Loop through text array
                    for i, text_content in enumerate(event['text']):
                        if isinstance(text_content, str):
                            texts_processed += 1
                            
                            # Split by line breaks
                            lines = text_content.split('\n')
                            original_order = lines.copy()
                            
                            print(f"    Text {i + 1}: Processing {len(lines)} lines")
                            
                            # Log priority assignments
                            for line_idx, line in enumerate(lines):
                                priority = get_priority(line)
                                if priority != 6:  # Only log non-default priorities
                                    priority_name = {
                                        1: "Aquire {",
                                        2: "[[Fans]]",
                                        3: "[[bond",
                                        4: "[[possible]]",
                                        5: "[[hint]]",
                                        7: "[[Energy"
                                    }.get(priority, "Unknown")
                                    print(f"      Line {line_idx + 1} (Priority {priority} - {priority_name}): {line[:50]}...")
                            
                            # Sort lines by priority
                            sorted_lines = sorted(lines, key=get_priority)
                            
                            # Reverse the array
                            sorted_lines.reverse()
                            
                            # Check if order changed
                            if original_order != sorted_lines:
                                texts_changed += 1
                                print(f"    Text {i + 1}: ORDER CHANGED!")
                                print(f"      Before: {[line[:30] + '...' if len(line) > 30 else line for line in original_order[:3]]}...")
                                print(f"      After:  {[line[:30] + '...' if len(line) > 30 else line for line in sorted_lines[:3]]}...")
                            else:
                                print(f"    Text {i + 1}: No change needed")
                            
                            # Join back with line breaks and store
                            event['text'][i] = '\n'.join(sorted_lines)
                        else:
                            print(f"    Text {i + 1}: Skipped (not a string)")
                else:
                    print(f"  Event {event_idx + 1}: No 'text' array found or not a list")
        else:
            print(f"Item {item_idx + 1}: No 'events' array found or not a list")
    
    # Summary
    print(f"\n=== PROCESSING SUMMARY ===")
    print(f"Items with events processed: {items_processed}")
    print(f"Events with text processed: {events_processed}")
    print(f"Text entries processed: {texts_processed}")
    print(f"Text entries changed: {texts_changed}")
    
    # Write the processed data
    output_path = output_file if output_file else input_file
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"\nProcessing complete! Output saved to: {output_path}")
    except Exception as e:
        print(f"Error writing to file: {e}")

def main():
    """
    Main function to run the script.
    """
    # Example usage - modify the file path as needed
    input_file = "./data.json"  # Change this to your JSON file path
    
    # Uncomment the line below if you want to save to a different file
    # output_file = "processed_data.json"
    # process_json_file(input_file, output_file)
    
    # This will overwrite the original file
    process_json_file(input_file)

if __name__ == "__main__":
    main()