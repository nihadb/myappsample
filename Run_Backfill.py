import TiBackfill
import sys

def main():
    # Check if the correct number of arguments are provided
    if len(sys.argv) != 3:
        print("Usage: python main.py <rundate>")
        sys.exit(1)

    # Extract the command line arguments
    runDate = sys.argv[1]
    isBackfill = sys.argv[2]
    
    # Call the function with the parameters
    TiBackfill.symbol_backfill(runDate, isBackfill)
    

if __name__ == "__main__":
    main()






######################
# python TiRun.py '2015-01-02 00:00:00' 'N'
