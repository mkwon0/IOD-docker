CXXFLAGS = -std=c++11 -O2
LDFLAGS = -static

SRCS = $(wildcard *.cc)
OBJS = $(SRCS:.cc=.o)
NAME = "stat-per-process"

all: $(NAME)

%.o: %.cc
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(NAME): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS) $(LIBS)

clean:
	rm -rf *.o $(NAME)
