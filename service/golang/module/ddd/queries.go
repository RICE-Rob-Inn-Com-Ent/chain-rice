package ddd

// GetSubdomainRoutingQuery represents a query to get subdomain routing
type GetSubdomainRoutingQuery struct {
	ProjectSlug   string
	SubdomainName string
}

// GetSubdomainRoutingResult represents the result of the query
type GetSubdomainRoutingResult struct {
	SubdomainURL  string
	Route         string
	ProjectSlug   string
	SubdomainName string
}

// GetSubdomainRoutingHandler handles the get subdomain routing query
type GetSubdomainRoutingHandler struct {
	routingService *RoutingService
}

// NewGetSubdomainRoutingHandler creates a new query handler
func NewGetSubdomainRoutingHandler(routingService *RoutingService) *GetSubdomainRoutingHandler {
	return &GetSubdomainRoutingHandler{
		routingService: routingService,
	}
}

// Handle executes the get subdomain routing query
func (h *GetSubdomainRoutingHandler) Handle(query GetSubdomainRoutingQuery) (*GetSubdomainRoutingResult, error) {
	route, err := h.routingService.ResolveSubdomain(query.ProjectSlug, query.SubdomainName)
	if err != nil {
		return nil, err
	}

	subdomainURL, err := h.routingService.BuildSubdomainURL(query.ProjectSlug, query.SubdomainName)
	if err != nil {
		return nil, err
	}

	return &GetSubdomainRoutingResult{
		SubdomainURL:  subdomainURL,
		Route:         route,
		ProjectSlug:   query.ProjectSlug,
		SubdomainName: query.SubdomainName,
	}, nil
}
